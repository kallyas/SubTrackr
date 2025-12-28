import Foundation
import CloudKit
import Combine

/// Represents the current state of CloudKit synchronization
enum SyncState: Equatable {
    case idle
    case syncing
    case synced(Date)
    case failed(CloudKitError)
    case offline

    var isError: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .synced(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .failed(let error):
            return "Sync failed: \(error.userFriendlyMessage)"
        case .offline:
            return "Offline mode"
        }
    }
}

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let database: CKDatabase

    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var error: CloudKitError?
    @Published var useLocalData = false
    @Published var syncState: SyncState = .idle

    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetries = 3
    private var retryWorkItem: DispatchWorkItem?
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.iden.SubTrackr")
        database = container.privateCloudDatabase
        
        checkAccountStatus()
        createSchemaIfNeeded()
        fetchSubscriptions()
        setupSubscription()
    }
    
    private func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    break
                case .noAccount:
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .restricted:
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .couldNotDetermine:
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .temporarilyUnavailable:
                    self?.useLocalData = true
                    self?.loadSampleData()
                @unknown default:
                    self?.useLocalData = true
                    self?.loadSampleData()
                }

                if let error = error {
                    // Silently handle error
                    _ = error
                }
            }
        }
    }
    
    private func createSchemaIfNeeded() {
        // Check if Subscription record type exists by trying to fetch its schema
        let operation = CKFetchRecordZoneChangesOperation()
        database.add(operation)
        
        // Create a test record to verify/create the schema
        let testRecord = CKRecord(recordType: "Subscription")
        testRecord["name"] = "Test"
        testRecord["cost"] = 0.0
        testRecord["currencyCode"] = "USD"
        testRecord["billingCycle"] = "Monthly"
        testRecord["startDate"] = Date()
        testRecord["category"] = "Other"
        testRecord["iconName"] = "app.fill"
        testRecord["isActive"] = true
        
        database.save(testRecord) { record, error in
            if let error = error as? CKError {
                if error.code == .unknownItem {
                    // The schema will be created automatically when we save the first record
                    // This is expected to fail the first time, but will create the schema
                }
            } else if let record = record {
                // Schema exists, delete the test record
                self.database.delete(withRecordID: record.recordID) { _, _ in }
            }
        }
    }
    
    private func setupSubscription() {
        let subscriptionID = "subscription-updates"
        let subscription = CKQuerySubscription(
            recordType: "Subscription",
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { _, error in
            // Silently handle subscription creation error
            _ = error
        }
    }
    
    func fetchSubscriptions() {
        if useLocalData {
            return // Sample data already loaded
        }

        isLoading = true
        error = nil
        syncState = .syncing

        let query = CKQuery(recordType: "Subscription", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
            switch result {
            case .success((let matchResults, _)):
                let records = matchResults.compactMap { matchResult in
                    switch matchResult.1 {
                    case .success(let record):
                        return record
                    case .failure:
                        return nil
                    }
                }
                self?.handleFetchResults(records: records, error: nil)
            case .failure(let error):
                self?.handleFetchResults(records: nil, error: error)
            }
        }
    }

    /// Retry fetch operation with exponential backoff
    private func retryFetch() {
        guard retryCount < maxRetries else {
            DispatchQueue.main.async {
                self.syncState = .failed(self.error ?? .fetchFailed("Max retries exceeded"))
            }
            return
        }

        retryCount += 1
        let delay = pow(2.0, Double(retryCount)) // Exponential backoff: 2, 4, 8 seconds

        retryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchSubscriptions()
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    private func handleFetchResults(records: [CKRecord]?, error: Error?) {
        DispatchQueue.main.async {
            self.isLoading = false

            if let error = error {
                let ckError = error as? CKError
                let cloudKitError: CloudKitError

                // Determine if error is retryable
                if let ckError = ckError {
                    switch ckError.code {
                    case .networkUnavailable, .networkFailure:
                        cloudKitError = .networkUnavailable
                    case .serviceUnavailable, .requestRateLimited:
                        cloudKitError = .serviceUnavailable(ckError.localizedDescription)
                    case .notAuthenticated:
                        cloudKitError = .accountNotAvailable
                    default:
                        cloudKitError = .fetchFailed(ckError.localizedDescription)
                    }

                    // Retry for transient errors
                    if ckError.code == .networkUnavailable ||
                       ckError.code == .networkFailure ||
                       ckError.code == .serviceUnavailable ||
                       ckError.code == .requestRateLimited {
                        self.error = cloudKitError
                        self.retryFetch()
                        return
                    }
                } else {
                    cloudKitError = .fetchFailed(error.localizedDescription)
                }

                self.error = cloudKitError
                self.syncState = .failed(cloudKitError)

                // Fallback to sample data on unrecoverable error
                if self.subscriptions.isEmpty {
                    self.useLocalData = true
                    self.loadSampleData()
                    self.syncState = .offline
                }
                return
            }

            guard let records = records else { return }

            self.subscriptions = records.compactMap { Subscription(from: $0) }
            self.retryCount = 0 // Reset retry count on success
            self.syncState = .synced(Date())
            self.error = nil
        }
    }
    
    private func loadSampleData() {
        subscriptions = SampleData.subscriptions
    }
    
    func saveSubscription(_ subscription: Subscription) {
        if useLocalData {
            if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                subscriptions[index] = subscription
            } else {
                subscriptions.append(subscription)
            }
            return
        }
        
        isLoading = true
        error = nil
        
        let record = subscription.toCKRecord()
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = CloudKitError.saveFailed(error.localizedDescription)
                    return
                }
                
                if let savedRecord = savedRecord,
                   let updatedSubscription = Subscription(from: savedRecord) {
                    if let index = self?.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                        self?.subscriptions[index] = updatedSubscription
                    } else {
                        self?.subscriptions.append(updatedSubscription)
                    }
                }
            }
        }
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        if useLocalData {
            subscriptions.removeAll { $0.id == subscription.id }
            return
        }
        
        isLoading = true
        error = nil
        
        let recordID = CKRecord.ID(recordName: subscription.id)
        
        database.delete(withRecordID: recordID) { [weak self] deletedRecordID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = CloudKitError.deleteFailed(error.localizedDescription)
                    return
                }
                
                self?.subscriptions.removeAll { $0.id == subscription.id }
            }
        }
    }
    
    func updateSubscription(_ subscription: Subscription) {
        saveSubscription(subscription)
    }
    
    func getSubscriptionsForDay(_ day: Int, month: Int, year: Int) -> [Subscription] {
        return subscriptions.filter { subscription in
            subscription.isActive && isSubscriptionActiveOnDay(subscription, day: day, month: month, year: year)
        }
    }
    
    private func isSubscriptionActiveOnDay(_ subscription: Subscription, day: Int, month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        let startDate = subscription.startDate
        
        if targetDate < startDate {
            return false
        }
        
        let billingDay = subscription.billingDayOfMonth
        
        switch subscription.billingCycle {
        case .monthly:
            return day == billingDay
        case .annual:
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            return month == startComponents.month && day == startComponents.day
        case .weekly:
            let weekday = calendar.component(.weekday, from: startDate)
            let targetWeekday = calendar.component(.weekday, from: targetDate)
            return weekday == targetWeekday
        case .quarterly, .semiAnnual:
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            let monthDiff = (month - startComponents.month! + 12) % 12
            let cycleMonths = subscription.billingCycle == .quarterly ? 3 : 6
            return monthDiff % cycleMonths == 0 && day == startComponents.day
        }
    }
}

enum CloudKitError: LocalizedError, Identifiable, Equatable {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case accountNotAvailable
    case networkUnavailable
    case serviceUnavailable(String)
    case updateFailed(String)

    static func == (lhs: CloudKitError, rhs: CloudKitError) -> Bool {
        return lhs.id == rhs.id
    }

    var id: String {
        switch self {
        case .fetchFailed(let message): return "fetch_\(message.prefix(50))"
        case .saveFailed(let message): return "save_\(message.prefix(50))"
        case .deleteFailed(let message): return "delete_\(message.prefix(50))"
        case .accountNotAvailable: return "account_unavailable"
        case .networkUnavailable: return "network_unavailable"
        case .serviceUnavailable(let message): return "service_unavailable_\(message.prefix(50))"
        case .updateFailed(let message): return "update_\(message.prefix(50))"
        }
    }

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch subscriptions: \(message)"
        case .saveFailed(let message):
            return "Failed to save subscription: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete subscription: \(message)"
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .networkUnavailable:
            return "Network is unavailable. Please check your internet connection and try again."
        case .serviceUnavailable(let message):
            return "iCloud service is temporarily unavailable: \(message)"
        case .updateFailed(let message):
            return "Failed to update subscription: \(message)"
        }
    }

    /// User-friendly short message suitable for UI display
    var userFriendlyMessage: String {
        switch self {
        case .fetchFailed:
            return "Couldn't load data"
        case .saveFailed:
            return "Couldn't save"
        case .deleteFailed:
            return "Couldn't delete"
        case .accountNotAvailable:
            return "iCloud not available"
        case .networkUnavailable:
            return "No internet connection"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .updateFailed:
            return "Couldn't update"
        }
    }

    /// Recovery suggestion for the user
    var recoverySuggestion: String {
        switch self {
        case .fetchFailed:
            return "Try pulling to refresh or check your iCloud settings."
        case .saveFailed, .updateFailed:
            return "Please try again in a moment."
        case .deleteFailed:
            return "Please try again or check if the subscription still exists."
        case .accountNotAvailable:
            return "Sign in to iCloud in Settings > [Your Name] > iCloud."
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
        case .serviceUnavailable:
            return "iCloud is experiencing issues. Please try again in a few minutes."
        }
    }
}
import Foundation
import CloudKit
import Combine

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var error: CloudKitError?
    @Published var useLocalData = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
                    print("iCloud account is available")
                case .noAccount:
                    print("No iCloud account, using local sample data")
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .restricted:
                    print("iCloud account restricted, using local sample data")
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .couldNotDetermine:
                    print("Could not determine iCloud status, using local sample data")
                    self?.useLocalData = true
                    self?.loadSampleData()
                case .temporarilyUnavailable:
                    print("iCloud temporarily unavailable, using local sample data")
                    self?.useLocalData = true
                    self?.loadSampleData()
                @unknown default:
                    print("Unknown iCloud status, using local sample data")
                    self?.useLocalData = true
                    self?.loadSampleData()
                }
                
                if let error = error {
                    print("Account status error: \(error.localizedDescription)")
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
                    print("Creating CloudKit schema for Subscription record type...")
                    // The schema will be created automatically when we save the first record
                    // This is expected to fail the first time, but will create the schema
                } else {
                    print("CloudKit schema check error: \(error.localizedDescription)")
                }
            } else if let record = record {
                // Schema exists, delete the test record
                self.database.delete(withRecordID: record.recordID) { _, _ in
                    print("CloudKit schema verified and test record cleaned up")
                }
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
            if let error = error {
                print("Failed to create subscription: \(error)")
            }
        }
    }
    
    func fetchSubscriptions() {
        if useLocalData {
            return // Sample data already loaded
        }
        
        isLoading = true
        error = nil
        
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
    
    private func handleFetchResults(records: [CKRecord]?, error: Error?) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            if let error = error {
                self.error = CloudKitError.fetchFailed(error.localizedDescription)
                // Fallback to sample data on error
                self.useLocalData = true
                self.loadSampleData()
                return
            }
            
            guard let records = records else { return }
            
            self.subscriptions = records.compactMap { Subscription(from: $0) }
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

enum CloudKitError: LocalizedError, Identifiable {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case accountNotAvailable
    case networkUnavailable
    
    var id: String {
        switch self {
        case .fetchFailed(let message): return "fetch_\(message)"
        case .saveFailed(let message): return "save_\(message)"
        case .deleteFailed(let message): return "delete_\(message)"
        case .accountNotAvailable: return "account_unavailable"
        case .networkUnavailable: return "network_unavailable"
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
            return "iCloud account is not available. Please sign in to iCloud."
        case .networkUnavailable:
            return "Network is unavailable. Please check your connection."
        }
    }
}
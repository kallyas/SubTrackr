import Foundation
import Combine
import WidgetKit
import UserNotifications

enum SortOption: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case priceHighToLow = "Price (High to Low)"
    case priceLowToHigh = "Price (Low to High)"
    case nextRenewal = "Next Renewal"
    case newest = "Newest First"
}

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var filteredSubscriptions: [Subscription] = []
    @Published var searchText = ""
    @Published var selectedCategory: SubscriptionCategory?
    @Published var sortOption: SortOption = .nameAscending
    @Published var showingAddSubscription = false
    @Published var editingSubscription: Subscription?
    @Published var showArchived = false

    // MARK: - Cached Computed Values
    private var _cachedMonthlyTotal: Double?
    private var _cachedCategoryTotals: [SubscriptionCategory: Double]?
    private var _cachedChartData: [(category: SubscriptionCategory, amount: Double, percentage: Double)]?
    private var lastCacheInvalidation: Date = Date()

    // MARK: - Undo Support
    @Published var recentlyDeletedSubscription: Subscription?
    @Published var showingUndoAlert = false
    private var undoWorkItem: DispatchWorkItem?

    private let cloudKitService = CloudKitService.shared
    private let currencyManager = CurrencyManager.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        cloudKitService.$subscriptions
            .sink { [weak self] newSubscriptions in
                self?.subscriptions = newSubscriptions
                self?.invalidateCache()
            }
            .store(in: &cancellables)

        // Debounced search filtering (300ms delay)
        let debouncedSearchText = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)

        Publishers.CombineLatest4($subscriptions, debouncedSearchText, $selectedCategory, $sortOption)
            .map { [weak self] subscriptions, searchText, selectedCategory, sortOption in
                let showArchived = self?.showArchived ?? false
                return self?.filterSubscriptions(subscriptions, searchText: searchText, category: selectedCategory, sortOption: sortOption, showArchived: showArchived) ?? []
            }
            .assign(to: \.filteredSubscriptions, on: self)
            .store(in: &cancellables)

        // Listen for currency changes and trigger UI updates
        currencyManager.$selectedCurrency
            .sink { [weak self] _ in
                self?.invalidateCache()
                self?.objectWillChange.send()
                self?.updateWidgetDataDebounced()
            }
            .store(in: &cancellables)

        // Debounced widget updates (500ms delay)
        $subscriptions
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWidgetData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Cache Invalidation

    private func invalidateCache() {
        _cachedMonthlyTotal = nil
        _cachedCategoryTotals = nil
        _cachedChartData = nil
        lastCacheInvalidation = Date()
    }

    private func updateWidgetDataDebounced() {
        updateWidgetData()
    }
    
    var monthlyTotal: Double {
        if let cached = _cachedMonthlyTotal {
            return cached
        }
        let currencyManager = CurrencyManager.shared
        let total = subscriptions.filter { $0.isActive && !$0.isArchived }.reduce(0) { total, subscription in
            let monthlyCostInOriginalCurrency = subscription.cost * subscription.billingCycle.monthlyEquivalent
            let convertedCost = currencyManager.convertToUserCurrency(monthlyCostInOriginalCurrency, from: subscription.currency)
            return total + convertedCost
        }
        _cachedMonthlyTotal = total
        return total
    }
    
    var annualTotal: Double {
        return monthlyTotal * 12
    }
    
    var yearOverYearComparison: Double? {
        // This would require historical data - returning nil for now
        // Could be implemented with price history tracking
        return nil
    }

    var categoryTotals: [SubscriptionCategory: Double] {
        if let cached = _cachedCategoryTotals {
            return cached
        }

        let activeSubscriptions = subscriptions.filter { $0.isActive && !$0.isArchived }
        let currencyManager = CurrencyManager.shared
        var totals: [SubscriptionCategory: Double] = [:]

        for subscription in activeSubscriptions {
            let monthlyCostInOriginalCurrency = subscription.cost * subscription.billingCycle.monthlyEquivalent
            let convertedAmount = currencyManager.convertToUserCurrency(monthlyCostInOriginalCurrency, from: subscription.currency)
            totals[subscription.category, default: 0] += convertedAmount
        }

        _cachedCategoryTotals = totals
        return totals
    }

    var chartData: [(category: SubscriptionCategory, amount: Double, percentage: Double)] {
        if let cached = _cachedChartData {
            return cached
        }
        let totals = categoryTotals
        let grandTotal = monthlyTotal

        let data = totals.map { category, amount in
            let percentage = grandTotal > 0 ? (amount / grandTotal) * 100 : 0
            return (category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }

        _cachedChartData = data
        return data
    }
    
    func addSubscription(_ subscription: Subscription) {
        cloudKitService.saveSubscription(subscription)
        invalidateCache()
        
        Task {
            await notificationManager.scheduleNotifications(for: subscription)
        }
    }

    func updateSubscription(_ subscription: Subscription) {
        cloudKitService.updateSubscription(subscription)
        invalidateCache()
        
        Task {
            await notificationManager.scheduleNotifications(for: subscription)
        }
    }
    
    func deleteSubscription(_ subscription: Subscription, withUndo: Bool = true) {
        if withUndo {
            // Store for undo
            recentlyDeletedSubscription = subscription
            showingUndoAlert = true

            // Cancel any existing undo timer
            undoWorkItem?.cancel()

            // Create new undo timer (5 seconds to undo)
            let workItem = DispatchWorkItem { [weak self] in
                self?.showingUndoAlert = false
                self?.recentlyDeletedSubscription = nil
            }
            undoWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
        }

        cloudKitService.deleteSubscription(subscription)
        invalidateCache()
        
        Task {
            await notificationManager.cancelNotifications(for: subscription)
        }
    }

    func undoDelete() {
        guard let subscription = recentlyDeletedSubscription else { return }
        undoWorkItem?.cancel()
        showingUndoAlert = false
        cloudKitService.saveSubscription(subscription)
        recentlyDeletedSubscription = nil
    }

    func confirmDelete() {
        undoWorkItem?.cancel()
        showingUndoAlert = false
        recentlyDeletedSubscription = nil
    }
    
    func toggleSubscriptionStatus(_ subscription: Subscription) {
        var updatedSubscription = subscription
        updatedSubscription.isActive.toggle()
        updateSubscription(updatedSubscription)
    }
    
    private func filterSubscriptions(_ subscriptions: [Subscription], searchText: String, category: SubscriptionCategory?, sortOption: SortOption, showArchived: Bool) -> [Subscription] {
        var filtered = subscriptions.filter { $0.isArchived == showArchived }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { subscription in
                subscription.name.localizedCaseInsensitiveContains(searchText) ||
                subscription.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sortSubscriptions(filtered, by: sortOption)
    }
    
    var archivedSubscriptions: [Subscription] {
        subscriptions.filter { $0.isArchived }
    }
    
    var activeSubscriptionsCount: Int {
        subscriptions.filter { $0.isActive && !$0.isArchived }.count
    }
    
    var archivedSubscriptionsCount: Int {
        subscriptions.filter { $0.isArchived }.count
    }
    
    func archiveSubscription(_ subscription: Subscription) {
        var updatedSubscription = subscription
        updatedSubscription.isArchived = true
        updateSubscription(updatedSubscription)
    }
    
    func unarchiveSubscription(_ subscription: Subscription) {
        var updatedSubscription = subscription
        updatedSubscription.isArchived = false
        updateSubscription(updatedSubscription)
    }
    
    private func sortSubscriptions(_ subscriptions: [Subscription], by sortOption: SortOption) -> [Subscription] {
        let currencyManager = CurrencyManager.shared
        
        switch sortOption {
        case .nameAscending:
            return subscriptions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return subscriptions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .priceHighToLow:
            return subscriptions.sorted { sub1, sub2 in
                let cost1 = currencyManager.convertToUserCurrency(sub1.cost * sub1.billingCycle.monthlyEquivalent, from: sub1.currency)
                let cost2 = currencyManager.convertToUserCurrency(sub2.cost * sub2.billingCycle.monthlyEquivalent, from: sub2.currency)
                return cost1 > cost2
            }
        case .priceLowToHigh:
            return subscriptions.sorted { sub1, sub2 in
                let cost1 = currencyManager.convertToUserCurrency(sub1.cost * sub1.billingCycle.monthlyEquivalent, from: sub1.currency)
                let cost2 = currencyManager.convertToUserCurrency(sub2.cost * sub2.billingCycle.monthlyEquivalent, from: sub2.currency)
                return cost1 < cost2
            }
        case .nextRenewal:
            return subscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }
        case .newest:
            return subscriptions.sorted { $0.startDate > $1.startDate }
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        sortOption = .nameAscending
    }
    
    func getUpcomingRenewals(days: Int = 7) -> [Subscription] {
        let calendar = Calendar.current
        let today = Date()
        let futureDate = calendar.date(byAdding: .day, value: days, to: today) ?? today
        
        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= today &&
            subscription.nextBillingDate <= futureDate
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    private func updateWidgetData() {
        WidgetDataManager.shared.saveWidgetData(
            subscriptions: subscriptions,
            monthlyTotal: monthlyTotal,
            userCurrencyCode: currencyManager.selectedCurrency.code
        )
    }
}

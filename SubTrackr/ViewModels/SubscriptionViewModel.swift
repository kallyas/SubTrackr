import Foundation
import Combine
import WidgetKit

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var filteredSubscriptions: [Subscription] = []
    @Published var searchText = ""
    @Published var selectedCategory: SubscriptionCategory?
    @Published var showingAddSubscription = false
    @Published var editingSubscription: Subscription?
    
    private let cloudKitService = CloudKitService.shared
    private let currencyManager = CurrencyManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        cloudKitService.$subscriptions
            .assign(to: \.subscriptions, on: self)
            .store(in: &cancellables)
        
        Publishers.CombineLatest3($subscriptions, $searchText, $selectedCategory)
            .map { subscriptions, searchText, selectedCategory in
                self.filterSubscriptions(subscriptions, searchText: searchText, category: selectedCategory)
            }
            .assign(to: \.filteredSubscriptions, on: self)
            .store(in: &cancellables)
        
        // Listen for currency changes and trigger UI updates
        currencyManager.$selectedCurrency
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.updateWidgetData()
            }
            .store(in: &cancellables)
        
        // Update widgets whenever subscriptions change
        $subscriptions
            .sink { [weak self] _ in
                self?.updateWidgetData()
            }
            .store(in: &cancellables)
    }
    
    var monthlyTotal: Double {
        let currencyManager = CurrencyManager.shared
        return subscriptions.filter(\.isActive).reduce(0) { total, subscription in
            let monthlyCostInOriginalCurrency = subscription.cost * subscription.billingCycle.monthlyEquivalent
            let convertedCost = currencyManager.convertToUserCurrency(monthlyCostInOriginalCurrency, from: subscription.currency)
            return total + convertedCost
        }
    }
    
    var categoryTotals: [SubscriptionCategory: Double] {
        let activeSubscriptions = subscriptions.filter(\.isActive)
        let currencyManager = CurrencyManager.shared
        var totals: [SubscriptionCategory: Double] = [:]
        
        for subscription in activeSubscriptions {
            let monthlyCostInOriginalCurrency = subscription.cost * subscription.billingCycle.monthlyEquivalent
            let convertedAmount = currencyManager.convertToUserCurrency(monthlyCostInOriginalCurrency, from: subscription.currency)
            totals[subscription.category, default: 0] += convertedAmount
        }
        
        return totals
    }
    
    var chartData: [(category: SubscriptionCategory, amount: Double, percentage: Double)] {
        let totals = categoryTotals
        let grandTotal = monthlyTotal
        
        return totals.map { category, amount in
            let percentage = grandTotal > 0 ? (amount / grandTotal) * 100 : 0
            return (category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    func addSubscription(_ subscription: Subscription) {
        cloudKitService.saveSubscription(subscription)
    }
    
    func updateSubscription(_ subscription: Subscription) {
        cloudKitService.updateSubscription(subscription)
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        cloudKitService.deleteSubscription(subscription)
    }
    
    func toggleSubscriptionStatus(_ subscription: Subscription) {
        var updatedSubscription = subscription
        updatedSubscription.isActive.toggle()
        updateSubscription(updatedSubscription)
    }
    
    private func filterSubscriptions(_ subscriptions: [Subscription], searchText: String, category: SubscriptionCategory?) -> [Subscription] {
        var filtered = subscriptions
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { subscription in
                subscription.name.localizedCaseInsensitiveContains(searchText) ||
                subscription.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
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
        let widgetSubscriptions = subscriptions.map { subscription in
            WidgetSubscription(
                id: subscription.id,
                name: subscription.name,
                cost: subscription.cost,
                currencyCode: subscription.currency.code,
                billingCycle: subscription.billingCycle.rawValue,
                nextBillingDate: subscription.nextBillingDate,
                category: subscription.category.rawValue,
                iconName: subscription.iconName,
                isActive: subscription.isActive
            )
        }
        
        let widgetData = WidgetData(
            subscriptions: widgetSubscriptions,
            monthlyTotal: monthlyTotal,
            userCurrencyCode: currencyManager.selectedCurrency.code,
            lastUpdated: Date()
        )
        
        WidgetDataManager.shared.saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
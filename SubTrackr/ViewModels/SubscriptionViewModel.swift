import Foundation
import Combine

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var filteredSubscriptions: [Subscription] = []
    @Published var searchText = ""
    @Published var selectedCategory: SubscriptionCategory?
    @Published var showingAddSubscription = false
    @Published var editingSubscription: Subscription?
    
    private let cloudKitService = CloudKitService.shared
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
    }
    
    var monthlyTotal: Double {
        subscriptions.filter(\.isActive).reduce(0) { total, subscription in
            total + (subscription.cost * subscription.billingCycle.monthlyEquivalent)
        }
    }
    
    var categoryTotals: [SubscriptionCategory: Double] {
        let activeSubscriptions = subscriptions.filter(\.isActive)
        var totals: [SubscriptionCategory: Double] = [:]
        
        for subscription in activeSubscriptions {
            let monthlyAmount = subscription.cost * subscription.billingCycle.monthlyEquivalent
            totals[subscription.category, default: 0] += monthlyAmount
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
}
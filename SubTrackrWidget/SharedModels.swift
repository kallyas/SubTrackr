import Foundation
import CloudKit

// Shared data models for widget
struct WidgetSubscription {
    let id: String
    let name: String
    let cost: Double
    let currencyCode: String
    let billingCycle: String
    let startDate: Date
    let isActive: Bool
    
    var nextBillingDate: Date {
        let calendar = Calendar.current
        switch billingCycle {
        case "Weekly":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case "Monthly":
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case "Quarterly":
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case "Semi-Annual":
            return calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        case "Annual":
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        default:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }
    
    var monthlyEquivalent: Double {
        switch billingCycle {
        case "Weekly": return 4.33
        case "Monthly": return 1.0
        case "Quarterly": return 1.0 / 3.0
        case "Semi-Annual": return 1.0 / 6.0
        case "Annual": return 1.0 / 12.0
        default: return 1.0
        }
    }
}

// Widget-specific Currency model
struct WidgetCurrency {
    let code: String
    let symbol: String
    
    static let USD = WidgetCurrency(code: "USD", symbol: "$")
    static let EUR = WidgetCurrency(code: "EUR", symbol: "€")
    static let GBP = WidgetCurrency(code: "GBP", symbol: "£")
    static let JPY = WidgetCurrency(code: "JPY", symbol: "¥")
    
    static let supportedCurrencies: [WidgetCurrency] = [.USD, .EUR, .GBP, .JPY]
    
    static func currency(for code: String) -> WidgetCurrency {
        return supportedCurrencies.first { $0.code == code } ?? .USD
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(amount)"
    }
}

// Shared UserDefaults for app group
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.iden.SubTrackr") ?? UserDefaults.standard
}

// Widget data manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private init() {}
    
    var selectedCurrency: WidgetCurrency {
        let code = UserDefaults.shared.string(forKey: "selectedCurrencyCode") ?? "USD"
        return WidgetCurrency.currency(for: code)
    }
    
    func getSampleSubscriptions() -> [WidgetSubscription] {
        return [
            WidgetSubscription(
                id: "1",
                name: "Netflix",
                cost: 15.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                startDate: Date(),
                isActive: true
            ),
            WidgetSubscription(
                id: "2",
                name: "Spotify",
                cost: 9.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                startDate: Date(),
                isActive: true
            ),
            WidgetSubscription(
                id: "3",
                name: "Adobe Creative",
                cost: 52.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                startDate: Date(),
                isActive: true
            )
        ]
    }
    
    func calculateMonthlyTotal(subscriptions: [WidgetSubscription]) -> Double {
        return subscriptions.filter { $0.isActive }.reduce(0) { total, subscription in
            return total + (subscription.cost * subscription.monthlyEquivalent)
        }
    }
    
    func getUpcomingRenewals(subscriptions: [WidgetSubscription]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= today &&
            subscription.nextBillingDate < nextWeek
        }.count
    }
}
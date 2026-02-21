import Foundation
import SwiftUI
import Combine

class BudgetManager: ObservableObject {
    static let shared = BudgetManager()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let monthlyBudget = "monthlyBudget"
        static let budgetCurrencyCode = "budgetCurrencyCode"
        static let budgetEnabled = "budgetEnabled"
        static let budgetWarningThreshold = "budgetWarningThreshold"
    }

    /// The budget amount stored in its original currency
    @Published var monthlyBudget: Double {
        didSet {
            userDefaults.set(monthlyBudget, forKey: Keys.monthlyBudget)
        }
    }

    /// The currency code in which the budget was set
    @Published var budgetCurrencyCode: String {
        didSet {
            userDefaults.set(budgetCurrencyCode, forKey: Keys.budgetCurrencyCode)
        }
    }

    @Published var budgetEnabled: Bool {
        didSet {
            userDefaults.set(budgetEnabled, forKey: Keys.budgetEnabled)
        }
    }

    @Published var warningThreshold: Double {
        didSet {
            userDefaults.set(warningThreshold, forKey: Keys.budgetWarningThreshold)
        }
    }

    /// Budget amount converted to the user's currently selected currency
    var budgetInUserCurrency: Double {
        let budgetCurrency = Currency.currency(for: budgetCurrencyCode) ?? .USD
        return CurrencyManager.shared.convertToUserCurrency(monthlyBudget, from: budgetCurrency)
    }

    /// Set budget with currency context
    func setBudget(amount: Double, currencyCode: String) {
        monthlyBudget = amount
        budgetCurrencyCode = currencyCode
    }
    
    var budgetWarningSent: Bool {
        get { userDefaults.bool(forKey: "budgetWarningSent") }
        set { userDefaults.set(newValue, forKey: "budgetWarningSent") }
    }
    
    var budgetExceededSent: Bool {
        get { userDefaults.bool(forKey: "budgetExceededSent") }
        set { userDefaults.set(newValue, forKey: "budgetExceededSent") }
    }
    
    private init() {
        self.monthlyBudget = userDefaults.double(forKey: Keys.monthlyBudget)
        self.budgetCurrencyCode = userDefaults.string(forKey: Keys.budgetCurrencyCode) ?? "USD"
        self.budgetEnabled = userDefaults.bool(forKey: Keys.budgetEnabled)
        self.warningThreshold = userDefaults.double(forKey: Keys.budgetWarningThreshold)

        if monthlyBudget == 0 {
            monthlyBudget = 100
        }
        if warningThreshold == 0 {
            warningThreshold = 80
        }
    }
    
    func resetMonthlyFlags() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = userDefaults.object(forKey: "budgetLastReset") as? Date {
            if !calendar.isSameMonth(as: now, as: lastReset) {
                budgetWarningSent = false
                budgetExceededSent = false
                userDefaults.set(now, forKey: "budgetLastReset")
            }
        } else {
            userDefaults.set(now, forKey: "budgetLastReset")
        }
    }
    
    func checkBudgetStatus(currentSpending: Double) -> BudgetStatus {
        let budgetConverted = budgetInUserCurrency
        guard budgetEnabled, budgetConverted > 0 else { return .normal }

        let percentage = (currentSpending / budgetConverted) * 100

        if percentage >= 100 {
            return .exceeded
        } else if percentage >= warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }
}

enum BudgetStatus {
    case normal
    case warning
    case exceeded
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .exceeded: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .exceeded: return "xmark.circle.fill"
        }
    }
    
    var message: String {
        switch self {
        case .normal: return "On track"
        case .warning: return "Approaching limit"
        case .exceeded: return "Over budget"
        }
    }
}

extension Calendar {
    func isSameMonth(as date1: Date, as date2: Date) -> Bool {
        let components1 = dateComponents([.year, .month], from: date1)
        let components2 = dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
}

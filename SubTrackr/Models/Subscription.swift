import Foundation
import CloudKit
import SwiftUI

struct Subscription: Identifiable, Hashable {
    let id: String
    var name: String
    var cost: Double
    var currency: Currency
    var billingCycle: BillingCycle
    var startDate: Date
    var category: SubscriptionCategory
    var iconName: String
    var isActive: Bool
    
    var nextBillingDate: Date {
        Calendar.current.date(byAdding: billingCycle.calendarComponent, value: billingCycle.value, to: startDate) ?? startDate
    }
    
    var billingDayOfMonth: Int {
        Calendar.current.component(.day, from: startDate)
    }
    
    init(id: String = UUID().uuidString, name: String, cost: Double, currency: Currency = CurrencyManager.shared.selectedCurrency, billingCycle: BillingCycle, startDate: Date, category: SubscriptionCategory, iconName: String = "app.fill", isActive: Bool = true) {
        self.id = id
        self.name = name
        self.cost = cost
        self.currency = currency
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.category = category
        self.iconName = iconName
        self.isActive = isActive
    }
    
    var formattedCost: String {
        return currency.formatAmount(cost)
    }
    
    var monthlyCost: Double {
        return cost * billingCycle.monthlyEquivalent
    }
}

enum BillingCycle: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnual = "Semi-Annual"
    case annual = "Annual"
    
    var id: String { rawValue }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .quarterly: return .month
        case .semiAnnual: return .month
        case .annual: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .weekly: return 1
        case .monthly: return 1
        case .quarterly: return 3
        case .semiAnnual: return 6
        case .annual: return 1
        }
    }
    
    var monthlyEquivalent: Double {
        switch self {
        case .weekly: return 4.33
        case .monthly: return 1.0
        case .quarterly: return 1.0 / 3.0
        case .semiAnnual: return 1.0 / 6.0
        case .annual: return 1.0 / 12.0
        }
    }
}

enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case software = "Software"
    case fitness = "Fitness"
    case gaming = "Gaming"
    case utilities = "Utilities"
    case news = "News"
    case music = "Music"
    case productivity = "Productivity"
    case other = "Other"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .streaming: return .red
        case .software: return .blue
        case .fitness: return .green
        case .gaming: return .purple
        case .utilities: return .orange
        case .news: return .gray
        case .music: return .pink
        case .productivity: return .teal
        case .other: return .brown
        }
    }
    
    var iconName: String {
        switch self {
        case .streaming: return "tv.fill"
        case .software: return "laptopcomputer"
        case .fitness: return "figure.run"
        case .gaming: return "gamecontroller.fill"
        case .utilities: return "bolt.fill"
        case .news: return "newspaper.fill"
        case .music: return "music.note"
        case .productivity: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

extension Subscription {
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let cost = record["cost"] as? Double,
              let billingCycleRaw = record["billingCycle"] as? String,
              let billingCycle = BillingCycle(rawValue: billingCycleRaw),
              let startDate = record["startDate"] as? Date,
              let categoryRaw = record["category"] as? String,
              let category = SubscriptionCategory(rawValue: categoryRaw) else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.name = name
        self.cost = cost
        
        // Handle currency - default to USD if not found
        let currencyCode = record["currencyCode"] as? String ?? "USD"
        self.currency = Currency.currency(for: currencyCode) ?? .USD
        
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.category = category
        self.iconName = record["iconName"] as? String ?? "app.fill"
        self.isActive = record["isActive"] as? Bool ?? true
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Subscription", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["cost"] = cost
        record["currencyCode"] = currency.code
        record["billingCycle"] = billingCycle.rawValue
        record["startDate"] = startDate
        record["category"] = category.rawValue
        record["iconName"] = iconName
        record["isActive"] = isActive
        return record
    }
}
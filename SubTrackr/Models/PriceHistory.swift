import Foundation
import CloudKit

struct PriceHistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let price: Double
    let date: Date
    let previousPrice: Double?
    let changeReason: PriceChangeReason?
    
    init(id: String = UUID().uuidString, price: Double, date: Date = Date(), previousPrice: Double? = nil, changeReason: PriceChangeReason? = nil) {
        self.id = id
        self.price = price
        self.date = date
        self.previousPrice = previousPrice
        self.changeReason = changeReason
    }
    
    var priceChange: Double? {
        guard let previous = previousPrice else { return nil }
        return price - previous
    }
    
    var priceChangePercentage: Double? {
        guard let previous = previousPrice, previous > 0 else { return nil }
        return ((price - previous) / previous) * 100
    }
    
    var isIncrease: Bool {
        guard let change = priceChange else { return false }
        return change > 0
    }
}

enum PriceChangeReason: String, Codable, CaseIterable, Identifiable {
    case renewal = "Renewal"
    case planUpgrade = "Plan Upgrade"
    case planDowngrade = "Plan Downgrade"
    case manual = "Manual Update"
    case detectedIncrease = "Price Increase Detected"
    case currencyAdjustment = "Currency Adjustment"
    case promotionalEnded = "Promo Ended"
    case other = "Other"
    
    var id: String { rawValue }
}

struct SharedMember: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String
    var shareType: ShareType
    var isPayer: Bool
    var addedDate: Date
    
    init(id: String = UUID().uuidString, name: String, email: String = "", shareType: ShareType = .family, isPayer: Bool = false, addedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.shareType = shareType
        self.isPayer = isPayer
        self.addedDate = addedDate
    }
}

enum ShareType: String, Codable, CaseIterable, Identifiable {
    case family = "Family"
    case friend = "Friend"
    case partner = "Partner"
    case colleague = "Colleague"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .family: return "household"
        case .friend: return "person.2.fill"
        case .partner: return "heart.fill"
        case .colleague: return "building.2.fill"
        case .other: return "person.fill"
        }
    }
}

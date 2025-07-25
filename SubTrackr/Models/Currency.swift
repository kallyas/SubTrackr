import Foundation
import SwiftUI

struct Currency: Identifiable, Hashable, Codable {
    let id: String
    let code: String
    let name: String
    let symbol: String
    let locale: Locale
    
    init(code: String, name: String, symbol: String) {
        self.id = code
        self.code = code
        self.name = name
        self.symbol = symbol
        self.locale = Locale(identifier: "en_US_POSIX")
    }
    
    // Custom formatter for this currency
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        formatter.locale = locale
        return formatter
    }
    
    func formatAmount(_ amount: Double) -> String {
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(amount)"
    }
}

extension Currency {
    static let USD = Currency(code: "USD", name: "US Dollar", symbol: "$")
    static let EUR = Currency(code: "EUR", name: "Euro", symbol: "€")
    static let GBP = Currency(code: "GBP", name: "British Pound", symbol: "£")
    static let JPY = Currency(code: "JPY", name: "Japanese Yen", symbol: "¥")
    static let CAD = Currency(code: "CAD", name: "Canadian Dollar", symbol: "C$")
    static let AUD = Currency(code: "AUD", name: "Australian Dollar", symbol: "A$")
    static let CHF = Currency(code: "CHF", name: "Swiss Franc", symbol: "₣")
    static let CNY = Currency(code: "CNY", name: "Chinese Yuan", symbol: "¥")
    static let SEK = Currency(code: "SEK", name: "Swedish Krona", symbol: "kr")
    static let NOK = Currency(code: "NOK", name: "Norwegian Krone", symbol: "kr")
    static let DKK = Currency(code: "DKK", name: "Danish Krone", symbol: "kr")
    static let PLN = Currency(code: "PLN", name: "Polish Złoty", symbol: "zł")
    static let CZK = Currency(code: "CZK", name: "Czech Koruna", symbol: "Kč")
    static let HUF = Currency(code: "HUF", name: "Hungarian Forint", symbol: "Ft")
    static let RUB = Currency(code: "RUB", name: "Russian Ruble", symbol: "₽")
    static let BRL = Currency(code: "BRL", name: "Brazilian Real", symbol: "R$")
    static let MXN = Currency(code: "MXN", name: "Mexican Peso", symbol: "$")
    static let INR = Currency(code: "INR", name: "Indian Rupee", symbol: "₹")
    static let KRW = Currency(code: "KRW", name: "South Korean Won", symbol: "₩")
    static let SGD = Currency(code: "SGD", name: "Singapore Dollar", symbol: "S$")
    static let HKD = Currency(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$")
    static let NZD = Currency(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$")
    static let ZAR = Currency(code: "ZAR", name: "South African Rand", symbol: "R")
    static let TRY = Currency(code: "TRY", name: "Turkish Lira", symbol: "₺")
    static let ILS = Currency(code: "ILS", name: "Israeli Shekel", symbol: "₪")
    static let AED = Currency(code: "AED", name: "UAE Dirham", symbol: "د.إ")
    static let SAR = Currency(code: "SAR", name: "Saudi Riyal", symbol: "﷼")
    
    static let supportedCurrencies: [Currency] = [
        .USD, .EUR, .GBP, .JPY, .CAD, .AUD, .CHF, .CNY,
        .SEK, .NOK, .DKK, .PLN, .CZK, .HUF, .RUB, .BRL,
        .MXN, .INR, .KRW, .SGD, .HKD, .NZD, .ZAR, .TRY,
        .ILS, .AED, .SAR
    ]
    
    static func currency(for code: String) -> Currency? {
        return supportedCurrencies.first { $0.code == code }
    }
    
    // Get user's preferred currency from locale
    static var userPreferred: Currency {
        let locale = Locale.current
        let currencyCode = locale.currencyCode ?? "USD"
        return currency(for: currencyCode) ?? .USD
    }
}

// Currency manager for app-wide currency settings
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var selectedCurrency: Currency {
        didSet {
            UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrencyCode")
        }
    }
    
    private init() {
        let savedCurrencyCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode")
        self.selectedCurrency = Currency.currency(for: savedCurrencyCode ?? "") ?? Currency.userPreferred
    }
    
    func formatAmount(_ amount: Double, currency: Currency? = nil) -> String {
        let currencyToUse = currency ?? selectedCurrency
        return currencyToUse.formatAmount(amount)
    }
    
    // Convert amount from one currency to another (simplified, would need real exchange rates)
    func convertAmount(_ amount: Double, from: Currency, to: Currency) -> Double {
        // This is a simplified conversion - in a real app, you'd use live exchange rates
        // For now, just return the same amount
        return amount
    }
}

// Extension for easy currency formatting in views
extension Double {
    func formatted(in currency: Currency) -> String {
        return currency.formatAmount(self)
    }
    
    func formatted() -> String {
        return CurrencyManager.shared.formatAmount(self)
    }
}
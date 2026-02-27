import Foundation
import SwiftUI
import WidgetKit

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
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
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
    static let THB = Currency(code: "THB", name: "Thai Baht", symbol: "฿")
    static let MYR = Currency(code: "MYR", name: "Malaysian Ringgit", symbol: "RM")
    static let IDR = Currency(code: "IDR", name: "Indonesian Rupiah", symbol: "Rp")
    static let PHP = Currency(code: "PHP", name: "Philippine Peso", symbol: "₱")
    static let VND = Currency(code: "VND", name: "Vietnamese Dong", symbol: "₫")
    static let EGP = Currency(code: "EGP", name: "Egyptian Pound", symbol: "£")
    static let NGN = Currency(code: "NGN", name: "Nigerian Naira", symbol: "₦")
    static let KES = Currency(code: "KES", name: "Kenyan Shilling", symbol: "KSh")
    static let UGX = Currency(code: "UGX", name: "Ugandan Shilling", symbol: "USh")
    static let TZS = Currency(code: "TZS", name: "Tanzanian Shilling", symbol: "TSh")
    static let RWF = Currency(code: "RWF", name: "Rwandan Franc", symbol: "FRw")
    static let ETB = Currency(code: "ETB", name: "Ethiopian Birr", symbol: "Br")
    static let XOF = Currency(code: "XOF", name: "West African CFA Franc", symbol: "CFA")
    static let XAF = Currency(code: "XAF", name: "Central African CFA Franc", symbol: "FCFA")
    static let ZMW = Currency(code: "ZMW", name: "Zambian Kwacha", symbol: "ZK")
    static let BWP = Currency(code: "BWP", name: "Botswana Pula", symbol: "P")
    static let MWK = Currency(code: "MWK", name: "Malawian Kwacha", symbol: "MK")
    static let SZL = Currency(code: "SZL", name: "Swazi Lilangeni", symbol: "L")
    static let LSL = Currency(code: "LSL", name: "Lesotho Loti", symbol: "L")
    static let NAD = Currency(code: "NAD", name: "Namibian Dollar", symbol: "N$")
    static let MZN = Currency(code: "MZN", name: "Mozambican Metical", symbol: "MT")
    static let AOA = Currency(code: "AOA", name: "Angolan Kwanza", symbol: "Kz")
    static let GHS = Currency(code: "GHS", name: "Ghanaian Cedi", symbol: "₵")
    static let MAD = Currency(code: "MAD", name: "Moroccan Dirham", symbol: "د.م.")
    static let TND = Currency(code: "TND", name: "Tunisian Dinar", symbol: "د.ت")
    static let LKR = Currency(code: "LKR", name: "Sri Lankan Rupee", symbol: "Rs")
    static let PKR = Currency(code: "PKR", name: "Pakistani Rupee", symbol: "Rs")
    static let BDT = Currency(code: "BDT", name: "Bangladeshi Taka", symbol: "৳")
    static let NPR = Currency(code: "NPR", name: "Nepalese Rupee", symbol: "Rs")
    static let MMK = Currency(code: "MMK", name: "Myanmar Kyat", symbol: "K")
    static let LAK = Currency(code: "LAK", name: "Lao Kip", symbol: "₭")
    static let KHR = Currency(code: "KHR", name: "Cambodian Riel", symbol: "៛")
    static let TWD = Currency(code: "TWD", name: "Taiwan Dollar", symbol: "NT$")
    static let CLP = Currency(code: "CLP", name: "Chilean Peso", symbol: "$")
    static let ARS = Currency(code: "ARS", name: "Argentine Peso", symbol: "$")
    static let COP = Currency(code: "COP", name: "Colombian Peso", symbol: "$")
    static let PEN = Currency(code: "PEN", name: "Peruvian Sol", symbol: "S/")
    static let UYU = Currency(code: "UYU", name: "Uruguayan Peso", symbol: "$U")
    static let BOB = Currency(code: "BOB", name: "Bolivian Boliviano", symbol: "Bs")
    static let PYG = Currency(code: "PYG", name: "Paraguayan Guarani", symbol: "₲")
    static let RON = Currency(code: "RON", name: "Romanian Leu", symbol: "lei")
    static let BGN = Currency(code: "BGN", name: "Bulgarian Lev", symbol: "лв")
    static let HRK = Currency(code: "HRK", name: "Croatian Kuna", symbol: "kn")
    static let RSD = Currency(code: "RSD", name: "Serbian Dinar", symbol: "дин")
    static let BAM = Currency(code: "BAM", name: "Bosnia Mark", symbol: "KM")
    static let MKD = Currency(code: "MKD", name: "Macedonian Denar", symbol: "ден")
    static let ALL = Currency(code: "ALL", name: "Albanian Lek", symbol: "L")
    static let ISK = Currency(code: "ISK", name: "Icelandic Krona", symbol: "kr")
    static let UAH = Currency(code: "UAH", name: "Ukrainian Hryvnia", symbol: "₴")
    static let BYN = Currency(code: "BYN", name: "Belarusian Ruble", symbol: "Br")
    static let KZT = Currency(code: "KZT", name: "Kazakhstani Tenge", symbol: "₸")
    static let UZS = Currency(code: "UZS", name: "Uzbekistani Som", symbol: "сум")
    static let AMD = Currency(code: "AMD", name: "Armenian Dram", symbol: "֏")
    static let GEL = Currency(code: "GEL", name: "Georgian Lari", symbol: "₾")
    static let AZN = Currency(code: "AZN", name: "Azerbaijani Manat", symbol: "₼")
    static let IRR = Currency(code: "IRR", name: "Iranian Rial", symbol: "﷼")
    static let IQD = Currency(code: "IQD", name: "Iraqi Dinar", symbol: "ع.د")
    static let AFN = Currency(code: "AFN", name: "Afghan Afghani", symbol: "؋")
    static let QAR = Currency(code: "QAR", name: "Qatari Riyal", symbol: "ر.ق")
    static let KWD = Currency(code: "KWD", name: "Kuwaiti Dinar", symbol: "د.ك")
    static let BHD = Currency(code: "BHD", name: "Bahraini Dinar", symbol: ".د.ب")
    static let OMR = Currency(code: "OMR", name: "Omani Rial", symbol: "ر.ع.")
    static let JOD = Currency(code: "JOD", name: "Jordanian Dinar", symbol: "د.ا")
    static let LBP = Currency(code: "LBP", name: "Lebanese Pound", symbol: "ل.ل")
    static let SYP = Currency(code: "SYP", name: "Syrian Pound", symbol: "£")
    
    // Pacific and Oceania
    static let FJD = Currency(code: "FJD", name: "Fijian Dollar", symbol: "FJ$")
    static let PGK = Currency(code: "PGK", name: "Papua New Guinea Kina", symbol: "K")
    static let SBD = Currency(code: "SBD", name: "Solomon Islands Dollar", symbol: "SI$")
    static let TOP = Currency(code: "TOP", name: "Tongan Paanga", symbol: "T$")
    static let VUV = Currency(code: "VUV", name: "Vanuatu Vatu", symbol: "VT")
    static let WST = Currency(code: "WST", name: "Samoan Tala", symbol: "WS$")
    
    // Caribbean and Americas
    static let BBD = Currency(code: "BBD", name: "Barbadian Dollar", symbol: "Bds$")
    static let BZD = Currency(code: "BZD", name: "Belize Dollar", symbol: "BZ$")
    static let BMD = Currency(code: "BMD", name: "Bermudian Dollar", symbol: "$")
    static let XCD = Currency(code: "XCD", name: "East Caribbean Dollar", symbol: "EC$")
    static let GTQ = Currency(code: "GTQ", name: "Guatemalan Quetzal", symbol: "Q")
    static let HNL = Currency(code: "HNL", name: "Honduran Lempira", symbol: "L")
    static let JMD = Currency(code: "JMD", name: "Jamaican Dollar", symbol: "J$")
    static let NIO = Currency(code: "NIO", name: "Nicaraguan Córdoba", symbol: "C$")
    static let PAB = Currency(code: "PAB", name: "Panamanian Balboa", symbol: "B/.")
    static let TTD = Currency(code: "TTD", name: "Trinidad and Tobago Dollar", symbol: "TT$")
    static let DOP = Currency(code: "DOP", name: "Dominican Peso", symbol: "RD$")
    static let CRC = Currency(code: "CRC", name: "Costa Rican Colón", symbol: "₡")
    static let HTG = Currency(code: "HTG", name: "Haitian Gourde", symbol: "G")
    static let CUP = Currency(code: "CUP", name: "Cuban Peso", symbol: "₱")
    
    // Additional Asian currencies
    static let BND = Currency(code: "BND", name: "Brunei Dollar", symbol: "B$")
    static let BTN = Currency(code: "BTN", name: "Bhutanese Ngultrum", symbol: "Nu.")
    static let MVR = Currency(code: "MVR", name: "Maldivian Rufiyaa", symbol: "Rf")
    static let MNT = Currency(code: "MNT", name: "Mongolian Tugrik", symbol: "₮")
    static let KPW = Currency(code: "KPW", name: "North Korean Won", symbol: "₩")
    
    // Additional European currencies
    static let MDL = Currency(code: "MDL", name: "Moldovan Leu", symbol: "L")
    
    // Additional currencies
    static let STN = Currency(code: "STN", name: "São Tomé and Príncipe Dobra", symbol: "Db")
    static let GMD = Currency(code: "GMD", name: "Gambian Dalasi", symbol: "D")
    static let GNF = Currency(code: "GNF", name: "Guinean Franc", symbol: "FG")
    static let LRD = Currency(code: "LRD", name: "Liberian Dollar", symbol: "L$")
    static let SLE = Currency(code: "SLE", name: "Sierra Leonean Leone", symbol: "Le")
    static let CVE = Currency(code: "CVE", name: "Cape Verdean Escudo", symbol: "$")
    static let DJF = Currency(code: "DJF", name: "Djiboutian Franc", symbol: "Fdj")
    static let ERN = Currency(code: "ERN", name: "Eritrean Nakfa", symbol: "Nfk")
    static let SOS = Currency(code: "SOS", name: "Somali Shilling", symbol: "S")
    static let SDP = Currency(code: "SDP", name: "Sudanese Pound", symbol: "£")
    static let SVC = Currency(code: "SVC", name: "Salvadoran Colón", symbol: "₡")
    
    // Popular currencies shown at the top for quick access
    static let popularCurrencies: [Currency] = [
        .USD, .EUR, .GBP, .JPY, .CAD, .AUD, .CHF, .CNY,
        .INR, .KRW, .SGD, .HKD, .NZD, .SEK, .NOK, .DKK,
        .BRL, .MXN, .ZAR, .TRY
    ]
    
    // All supported currencies (full list - users can have subscriptions in any currency)
    static let supportedCurrencies: [Currency] = [
        // Major World Currencies
        .USD, .EUR, .GBP, .JPY, .CAD, .AUD, .CHF, .CNY,
        
        // European Currencies
        .SEK, .NOK, .DKK, .PLN, .CZK, .HUF, .RUB, .RON, .BGN, .HRK,
        .RSD, .BAM, .MKD, .ALL, .ISK, .UAH, .BYN, .MDL,
        
        // Asian Currencies
        .INR, .KRW, .SGD, .HKD, .THB, .MYR, .IDR, .PHP, .VND,
        .LKR, .PKR, .BDT, .NPR, .MMK, .LAK, .KHR, .TWD,
        .BND, .BTN, .MVR, .MNT, .KPW,
        
        // Middle Eastern Currencies
        .AED, .SAR, .QAR, .KWD, .BHD, .OMR, .JOD, .LBP, .SYP,
        .TRY, .ILS, .IRR, .IQD, .AFN,
        
        // African Currencies
        .ZAR, .NGN, .KES, .UGX, .TZS, .RWF, .ETB, .EGP,
        .XOF, .XAF, .ZMW, .BWP, .MWK, .SZL, .LSL, .NAD,
        .MZN, .AOA, .GHS, .MAD, .TND, .STN, .GMD, .GNF,
        .LRD, .SLE, .CVE, .DJF, .ERN, .SOS, .SDP,
        
        // American Currencies
        .BRL, .MXN, .CLP, .ARS, .COP, .PEN, .UYU, .BOB, .PYG,
        .BBD, .BZD, .BMD, .XCD, .GTQ, .HNL, .JMD, .NIO,
        .PAB, .TTD, .DOP, .CRC, .HTG, .CUP, .SVC,
        
        // Central Asian Currencies
        .KZT, .UZS, .AMD, .GEL, .AZN,
        
        // Pacific and Oceania Currencies
        .NZD, .FJD, .PGK, .SBD, .TOP, .VUV, .WST
    ]
    
    static func currency(for code: String) -> Currency? {
        return supportedCurrencies.first { $0.code == code }
    }
    
    // Get user's preferred currency from locale
    static var userPreferred: Currency {
        let locale = Locale.current
        let currencyCode: String
        if #available(iOS 16.0, *) {
            currencyCode = locale.currency?.identifier ?? "USD"
        } else {
            currencyCode = locale.currencyCode ?? "USD"
        }
        return currency(for: currencyCode) ?? .USD
    }
}

// Currency manager for app-wide currency settings
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var selectedCurrency: Currency {
        didSet {
            UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrencyCode")
            // Refresh exchange rates when currency changes
            refreshExchangeRates()
            // Reload widgets when currency changes
            reloadWidgets()
        }
    }
    
    private let exchangeService = CurrencyExchangeService.shared
    
    private init() {
        let savedCurrencyCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode")
        self.selectedCurrency = Currency.currency(for: savedCurrencyCode ?? "") ?? Currency.userPreferred
    }
    
    func formatAmount(_ amount: Double, currency: Currency? = nil) -> String {
        let currencyToUse = currency ?? selectedCurrency
        return currencyToUse.formatAmount(amount)
    }
    
    func formatAmountInUserCurrency(_ amount: Double, originalCurrency: Currency) -> String {
        let convertedAmount = convertToUserCurrency(amount, from: originalCurrency)
        return selectedCurrency.formatAmount(convertedAmount)
    }
    
    func convertToUserCurrency(_ amount: Double, from: Currency) -> Double {
        return exchangeService.convertAmount(amount, from: from, to: selectedCurrency)
    }
    
    func convertAmount(_ amount: Double, from: Currency, to: Currency) -> Double {
        return exchangeService.convertAmount(amount, from: from, to: to)
    }
    
    func getExchangeRate(from: Currency, to: Currency) -> Double? {
        return exchangeService.getExchangeRate(from: from, to: to)
    }
    
    func refreshExchangeRates() {
        exchangeService.fetchExchangeRates(baseCurrency: selectedCurrency.code)
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
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
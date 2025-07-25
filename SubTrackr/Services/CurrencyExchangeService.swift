import Foundation
import Combine

class CurrencyExchangeService: ObservableObject {
    static let shared = CurrencyExchangeService()
    
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var error: ExchangeRateError?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    
    private init() {
        loadCachedRates()
        fetchExchangeRates()
    }
    
    func fetchExchangeRates(baseCurrency: String = "USD") {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(baseURL)/\(baseCurrency)") else {
            error = .invalidURL
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = .networkError(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.exchangeRates = response.rates
                    self?.lastUpdated = Date()
                    self?.cacheRates()
                }
            )
            .store(in: &cancellables)
    }
    
    func convertAmount(_ amount: Double, from: Currency, to: Currency) -> Double {
        guard from.code != to.code else { return amount }
        
        // If we don't have exchange rates, return original amount
        guard !exchangeRates.isEmpty else { return amount }
        
        // Convert via USD as base currency
        let fromRate = exchangeRates[from.code] ?? 1.0
        let toRate = exchangeRates[to.code] ?? 1.0
        
        // Convert to USD first, then to target currency
        let usdAmount = amount / fromRate
        return usdAmount * toRate
    }
    
    func getExchangeRate(from: Currency, to: Currency) -> Double? {
        guard from.code != to.code else { return 1.0 }
        
        let fromRate = exchangeRates[from.code] ?? 1.0
        let toRate = exchangeRates[to.code] ?? 1.0
        
        return toRate / fromRate
    }
    
    private func cacheRates() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(exchangeRates) {
            UserDefaults.standard.set(data, forKey: "cachedExchangeRates")
            UserDefaults.standard.set(Date(), forKey: "exchangeRatesTimestamp")
        }
    }
    
    private func loadCachedRates() {
        guard let data = UserDefaults.standard.data(forKey: "cachedExchangeRates"),
              let timestamp = UserDefaults.standard.object(forKey: "exchangeRatesTimestamp") as? Date else {
            return
        }
        
        // Use cached rates if they're less than 1 hour old
        let oneHourAgo = Date().addingTimeInterval(-3600)
        guard timestamp > oneHourAgo else { return }
        
        let decoder = JSONDecoder()
        if let rates = try? decoder.decode([String: Double].self, from: data) {
            exchangeRates = rates
            lastUpdated = timestamp
        }
    }
    
    var needsUpdate: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return lastUpdated < oneHourAgo
    }
    
    func refreshIfNeeded() {
        if needsUpdate {
            fetchExchangeRates()
        }
    }
}

struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

enum ExchangeRateError: LocalizedError, Identifiable {
    case invalidURL
    case networkError(String)
    case decodingError
    
    var id: String {
        switch self {
        case .invalidURL: return "invalid_url"
        case .networkError(let message): return "network_\(message)"
        case .decodingError: return "decoding_error"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for exchange rate service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode exchange rate data"
        }
    }
}
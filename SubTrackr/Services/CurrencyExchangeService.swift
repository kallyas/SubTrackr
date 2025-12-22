import Foundation
import Combine

class CurrencyExchangeService: ObservableObject {
    static let shared = CurrencyExchangeService()

    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var error: ExchangeRateError?
    @Published var isStale = false

    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private var debounceWorkItem: DispatchWorkItem?
    private let requestTimeout: TimeInterval = 10.0 // 10 second timeout
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    private let staleDataWarningInterval: TimeInterval = 7200 // 2 hours
    private let maxCacheAge: TimeInterval = 86400 // 24 hours

    private init() {
        loadCachedRates()
        fetchExchangeRates()
        setupStaleDataMonitoring()
    }

    /// Monitor for stale data and notify UI
    private func setupStaleDataMonitoring() {
        Timer.publish(every: 300, on: .main, in: .common) // Check every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkIfDataIsStale()
            }
            .store(in: &cancellables)
    }

    private func checkIfDataIsStale() {
        guard let lastUpdated = lastUpdated else {
            isStale = true
            return
        }

        let age = Date().timeIntervalSince(lastUpdated)
        isStale = age > staleDataWarningInterval

        // Auto-refresh if data is very old and not currently loading
        if age > cacheExpiryInterval && !isLoading {
            refreshIfNeeded()
        }
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

        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        let session = URLSession(configuration: config)

        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if let exchangeError = error as? ExchangeRateError {
                            self?.error = exchangeError
                        } else if error is URLError {
                            let urlError = error as! URLError
                            switch urlError.code {
                            case .notConnectedToInternet, .networkConnectionLost:
                                self?.error = .networkError("No internet connection")
                            case .timedOut:
                                self?.error = .timeout
                            default:
                                self?.error = .networkError(urlError.localizedDescription)
                            }
                        } else {
                            self?.error = .networkError(error.localizedDescription)
                        }
                        print("Exchange rate fetch failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.exchangeRates = response.rates
                    self?.lastUpdated = Date()
                    self?.isStale = false
                    self?.cacheRates()
                    print("Exchange rates updated successfully")
                }
            )
            .store(in: &cancellables)
    }

    /// Debounced fetch to prevent excessive API calls
    func fetchExchangeRatesDebounced(baseCurrency: String = "USD", delay: TimeInterval = 2.0) {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchExchangeRates(baseCurrency: baseCurrency)
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
            isStale = true
            return
        }

        let age = Date().timeIntervalSince(timestamp)

        // Don't use cache if it's older than 24 hours
        guard age < maxCacheAge else {
            isStale = true
            print("Cached exchange rates are too old (\(Int(age/3600)) hours), fetching fresh data")
            return
        }

        let decoder = JSONDecoder()
        if let rates = try? decoder.decode([String: Double].self, from: data) {
            exchangeRates = rates
            lastUpdated = timestamp
            isStale = age > staleDataWarningInterval
            print("Loaded cached exchange rates (age: \(Int(age/60)) minutes)")
        }
    }

    var needsUpdate: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let age = Date().timeIntervalSince(lastUpdated)
        return age > cacheExpiryInterval
    }

    var isCacheExpired: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let age = Date().timeIntervalSince(lastUpdated)
        return age > maxCacheAge
    }

    var cacheAgeDescription: String {
        guard let lastUpdated = lastUpdated else { return "Never updated" }
        let age = Date().timeIntervalSince(lastUpdated)
        let hours = Int(age / 3600)
        let minutes = Int((age.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }

    func refreshIfNeeded() {
        if needsUpdate && !isLoading {
            fetchExchangeRates()
        }
    }

    /// Force refresh exchange rates regardless of cache status
    func forceRefresh() {
        fetchExchangeRates()
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
    case timeout
    case staleData

    var id: String {
        switch self {
        case .invalidURL: return "invalid_url"
        case .networkError(let message): return "network_\(message.prefix(50))"
        case .decodingError: return "decoding_error"
        case .timeout: return "timeout"
        case .staleData: return "stale_data"
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
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .staleData:
            return "Exchange rate data is outdated. Pull to refresh."
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .invalidURL, .decodingError:
            return "Service error"
        case .networkError:
            return "Connection failed"
        case .timeout:
            return "Request timed out"
        case .staleData:
            return "Data is outdated"
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .invalidURL, .decodingError:
            return "Please try again later or contact support if the issue persists."
        case .networkError:
            return "Check your internet connection and try again."
        case .timeout:
            return "The request took too long. Check your connection and try again."
        case .staleData:
            return "Pull down to refresh exchange rates."
        }
    }
}
import SwiftUI

struct CurrencyPickerView: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.supportedCurrencies
        } else {
            return Currency.supportedCurrencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Exchange rate info
                if let lastUpdated = exchangeService.lastUpdated {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Rates updated \(lastUpdated, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if exchangeService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button("Refresh") {
                                currencyManager.refreshExchangeRates()
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search currencies...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Currency list
                List {
                    ForEach(filteredCurrencies) { currency in
                        CurrencyRow(
                            currency: currency,
                            isSelected: currency.code == currencyManager.selectedCurrency.code,
                            exchangeRate: getExchangeRate(for: currency)
                        ) {
                            currencyManager.selectedCurrency = currency
                            HapticManager.shared.lightImpact()
                            dismiss()
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            exchangeService.refreshIfNeeded()
        }
    }
    
    private func getExchangeRate(for currency: Currency) -> Double? {
        guard currency.code != currencyManager.selectedCurrency.code else { return nil }
        return currencyManager.getExchangeRate(from: currencyManager.selectedCurrency, to: currency)
    }
}

struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    let exchangeRate: Double?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currency.symbol)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 30, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(currency.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let rate = exchangeRate {
                        Text("1.00 = \(currency.formatAmount(rate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

#Preview {
    CurrencyPickerView()
}
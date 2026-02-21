import SwiftUI

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var budgetManager = BudgetManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var budgetAmount: String = ""
    @State private var selectedPreset: Int?
    
    private let presets: [Double] = [50, 100, 150, 200, 300, 500]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Monthly Budget")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.label)
                        
                        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxs) {
                            Text(currencyManager.selectedCurrency.symbol)
                                .font(DesignSystem.Typography.title2)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                            
                            TextField("0", text: $budgetAmount)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .foregroundStyle(DesignSystem.Colors.label)
                        }
                        
                        Text("You'll receive notifications when spending reaches 80% and 100% of this amount.")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                budgetAmount = String(Int(preset))
                                selectedPreset = presets.firstIndex(of: preset)
                            } label: {
                                Text("\(currencyManager.selectedCurrency.symbol)\(Int(preset))")
                                    .font(DesignSystem.Typography.callout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedPreset == presets.firstIndex(of: preset) ? .white : DesignSystem.Colors.label)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                            .fill(selectedPreset == presets.firstIndex(of: preset) ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryBackground)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Quick Select")
                }
                
                Section {
                    HStack {
                        Text("Currency")
                            .font(DesignSystem.Typography.callout)
                        Spacer()
                        Text("\(currencyManager.selectedCurrency.name) (\(currencyManager.selectedCurrency.symbol))")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                    .disabled(budgetAmount.isEmpty || (Double(budgetAmount) ?? 0) <= 0)
                }
            }
            .onAppear {
                // Show budget converted to user's current currency
                let budgetInCurrentCurrency = budgetManager.budgetInUserCurrency
                budgetAmount = String(Int(budgetInCurrentCurrency))
                if let index = presets.firstIndex(of: budgetInCurrentCurrency) {
                    selectedPreset = index
                }
            }
        }
    }
    
    private func saveBudget() {
        if let amount = Double(budgetAmount), amount > 0 {
            budgetManager.setBudget(
                amount: amount,
                currencyCode: currencyManager.selectedCurrency.code
            )
            budgetManager.budgetEnabled = true
            dismiss()
        }
    }
}

#Preview {
    BudgetEditorView()
}

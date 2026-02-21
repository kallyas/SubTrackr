import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""
    @State private var selectedTemplate: SubscriptionTemplate?
    
    private var filteredTemplates: [SubscriptionTemplate] {
        SubscriptionTemplate.search(searchText)
    }
    
    private var groupedTemplates: [(String, [SubscriptionTemplate])] {
        let grouped = Dictionary(grouping: filteredTemplates) { $0.category.rawValue }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if filteredTemplates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search services")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $selectedTemplate) { template in
                EditSubscriptionView(subscription: nil) { subscription in
                    CloudKitService.shared.saveSubscription(subscription)
                    dismiss()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(
                            name: .applyTemplate,
                            object: nil,
                            userInfo: ["template": template]
                        )
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            
            Text("No templates found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.label)
            
            Text("Try a different search term")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            
            Spacer()
        }
    }
    
    private var templateList: some View {
        List {
            ForEach(groupedTemplates, id: \.0) { category, templates in
                Section(category) {
                    ForEach(templates) { template in
                        TemplateRow(template: template, currency: currencyManager.selectedCurrency)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct TemplateRow: View {
    let template: SubscriptionTemplate
    let currency: Currency
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.categorySubtle(template.category.color))
                    .frame(width: 44, height: 44)
                
                Image(systemName: template.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(template.category.color)
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(template.name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)
                
                Text(template.category.rawValue)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            
            Spacer()
            
            Text(template.suggestedCost(in: currency))
                .font(DesignSystem.Typography.callout)
                .fontWeight(.medium)
                .foregroundStyle(DesignSystem.Colors.label)
            
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.accent)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

extension Notification.Name {
    static let applyTemplate = Notification.Name("com.subtrackr.applyTemplate")
}

#Preview {
    TemplatePickerView()
}

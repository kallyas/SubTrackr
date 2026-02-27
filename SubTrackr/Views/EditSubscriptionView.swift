import SwiftUI

struct EditSubscriptionView: View {
    let subscription: Subscription?
    var currentMonthlyTotal: Double = 0
    let onSave: (Subscription) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var budgetManager = BudgetManager.shared
    
    @State private var name = ""
    @State private var cost = ""
    @State private var selectedCurrency = Currency.USD
    @State private var billingCycle = BillingCycle.monthly
    @State private var startDate = Date()
    @State private var category = SubscriptionCategory.streaming
    @State private var iconName = "app.fill"
    @State private var isActive = true
    
    @State private var isTrial = false
    @State private var trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @State private var showingIconPicker = false
    @State private var showingTemplatePicker = false
    
    private var isEditing: Bool {
        subscription != nil
    }
    
    private var title: String {
        isEditing ? "Edit Subscription" : "Add Subscription"
    }
    
    private var canSave: Bool {
        !name.isEmpty && !cost.isEmpty && Double(cost) != nil
    }
    
    private var newSubscriptionMonthlyCost: Double {
        guard let costValue = Double(cost), costValue > 0 else { return 0 }
        return costValue * billingCycle.monthlyEquivalent
    }
    
    private var newSubscriptionMonthlyCostInUserCurrency: Double {
        currencyManager.convertToUserCurrency(newSubscriptionMonthlyCost, from: selectedCurrency)
    }
    
    private var budgetWarning: (show: Bool, status: BudgetStatus, newTotal: Double)? {
        guard budgetManager.budgetEnabled,
              budgetManager.budgetInUserCurrency > 0,
              !isEditing,
              let costValue = Double(cost), costValue > 0 else {
            return nil
        }
        
        let newTotal = currentMonthlyTotal + newSubscriptionMonthlyCostInUserCurrency
        let newStatus = budgetManager.checkBudgetStatus(currentSpending: newTotal)
        
        if newStatus == .warning || newStatus == .exceeded {
            return (true, newStatus, newTotal)
        }
        return nil
    }
    
    @ViewBuilder
    private var budgetWarningView: some View {
        if let warning = budgetWarning, warning.show {
            Section {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: warning.status.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(warning.status.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(warning.status == .exceeded ? "Over Budget" : "Approaching Limit")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(warning.status.color)
                        
                        let budget = budgetManager.budgetInUserCurrency
                        let percentage = Int((warning.newTotal / budget) * 100)
                        Text("This will bring your total to \(currencyManager.formatAmount(warning.newTotal)) (\(percentage)% of budget)")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            .listRowBackground(warning.status.color.opacity(0.1))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                budgetWarningView
                
                basicInfoSection
                billingSection
                trialSection
                categorySection
                iconSection

                if isEditing {
                    statusSection
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.shared.success()
                        saveSubscription()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            loadSubscriptionData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .applyTemplate)) { notification in
            if let template = notification.userInfo?["template"] as? SubscriptionTemplate {
                name = template.name
                iconName = template.iconName
                category = template.category
                billingCycle = template.billingCycle
                selectedCurrency = CurrencyManager.shared.selectedCurrency
                cost = String(format: "%.2f", template.typicalCostValue(in: selectedCurrency))
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $iconName)
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerView()
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            if !isEditing {
                Button {
                    showingTemplatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                        Text("Browse Templates")
                            .foregroundStyle(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            TextField("Service Name", text: $name)
                .textInputAutocapitalization(.words)
            
            HStack {
                Text(selectedCurrency.symbol)
                    .foregroundColor(.secondary)
                TextField("0.00", text: $cost)
                    .keyboardType(.decimalPad)
                
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(Currency.supportedCurrencies) { currency in
                        Text(currency.code).tag(currency)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var billingSection: some View {
        Section("Billing") {
            Picker("Billing Cycle", selection: $billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.rawValue).tag(cycle)
                }
            }

            DatePicker(
                "Start Date",
                selection: $startDate,
                displayedComponents: [.date]
            )
        }
    }

    private var trialSection: some View {
        Section {
            Toggle(isOn: $isTrial) {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(.orange)
                    Text("Free Trial")
                }
            }

            if isTrial {
                DatePicker(
                    "Trial Ends",
                    selection: $trialEndDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )

                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.blue)
                    Text("Reminder 3 days before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Trial")
        } footer: {
            if isTrial {
                Text("You'll receive notifications before your trial expires to avoid unexpected charges.")
            }
        }
    }
    
    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(SubscriptionCategory.allCases) { cat in
                    HStack {
                        Image(systemName: cat.iconName)
                            .foregroundColor(cat.color)
                        Text(cat.rawValue)
                    }
                    .tag(cat)
                }
            }
        }
    }
    
    private var iconSection: some View {
        Section("Icon") {
            Button {
                showingIconPicker = true
            } label: {
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(Color.accentColor)
                        .frame(width: 30)
                    
                    Text("Choose Icon")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            Toggle("Active", isOn: $isActive)
        }
    }
    
    private func loadSubscriptionData() {
        guard let subscription = subscription else {
            // For new subscriptions, use user's current currency
            selectedCurrency = currencyManager.selectedCurrency
            return
        }

        name = subscription.name
        cost = String(subscription.cost)
        selectedCurrency = subscription.currency
        billingCycle = subscription.billingCycle
        startDate = subscription.startDate
        category = subscription.category
        iconName = subscription.iconName
        isActive = subscription.isActive
        isTrial = subscription.isTrial
        if let endDate = subscription.trialEndDate {
            trialEndDate = endDate
        }
    }
    
    private func saveSubscription() {
        guard let costValue = Double(cost) else { return }

        let subscriptionToSave = Subscription(
            id: subscription?.id ?? UUID().uuidString,
            name: name,
            cost: costValue,
            currency: selectedCurrency,
            billingCycle: billingCycle,
            startDate: startDate,
            category: category,
            iconName: iconName,
            isActive: isActive,
            isArchived: subscription?.isArchived ?? false,
            isTrial: isTrial,
            trialEndDate: isTrial ? trialEndDate : nil,
            tags: subscription?.tags ?? []
        )

        // Schedule trial notification if this is a trial
        if isTrial {
            Task {
                await NotificationManager.shared.scheduleFreeTrialReminder(
                    for: subscriptionToSave,
                    expirationDate: trialEndDate
                )
            }
        }

        onSave(subscriptionToSave)
        dismiss()
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    private let icons = [
        // Entertainment & Streaming
        "tv.fill", "play.rectangle.fill", "sparkles.tv.fill", "tv.and.hifispeaker.fill",
        "movieclapper.fill", "video.fill", "camera.fill", "photo.fill",
        
        // Music & Audio
        "music.note", "headphones", "airpods", "speaker.fill", "hifispeaker.fill",
        "radio.fill", "waveform", "music.note.list", "mic.fill",
        
        // Gaming
        "gamecontroller.fill", "arcade.stick", "dice.fill", "target",
        
        // Software & Productivity
        "laptopcomputer", "desktopcomputer", "iphone", "ipad", "applewatch",
        "doc.text.fill", "folder.fill", "note.text", "pencil", "paintbrush.fill",
        "terminal.fill", "chevron.left.forwardslash.chevron.right", "gear",
        
        // Cloud & Storage
        "cloud.fill", "icloud.fill", "externaldrive.fill", "internaldrive.fill",
        "server.rack", "wifi", "antenna.radiowaves.left.and.right",
        
        // News & Reading
        "newspaper.fill", "magazine.fill", "book.fill", "books.vertical.fill",
        "character.book.closed.fill", "text.book.closed.fill",
        
        // Health & Fitness
        "figure.run", "dumbbell.fill", "tennis.racket", "football.fill",
        "figure.yoga", "heart.fill", "cross.vial.fill", "pill.fill",
        
        // Transportation
        "car.fill", "bus.fill", "airplane", "bicycle", "scooter", "ferry.fill",
        
        // Shopping & Finance
        "bag.fill", "cart.fill", "creditcard.fill", "banknote.fill",
        "dollarsign.circle.fill", "building.columns.fill", "chart.line.uptrend.xyaxis",
        
        // Utilities & Services
        "bolt.fill", "flame.fill", "drop.fill", "leaf.fill", "snowflake",
        "house.fill", "building.2.fill", "storefront.fill", "wrench.fill",
        
        // Communication
        "message.fill", "envelope.fill", "phone.fill", "video.fill",
        "megaphone.fill", "bubble.left.and.bubble.right.fill",
        
        // General
        "app.fill", "star.fill", "heart.fill", "flag.fill", "tag.fill",
        "shield.fill", "lock.fill", "key.fill", "globe", "location.fill"
    ]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : Color.accentColor)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.accentColor : Color.accentColor.opacity(0.1))
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditSubscriptionView(subscription: nil, currentMonthlyTotal: 0) { _ in }
}
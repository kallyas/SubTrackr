import SwiftUI

struct EditSubscriptionView: View {
    let subscription: Subscription?
    let onSave: (Subscription) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    
    @State private var name = ""
    @State private var cost = ""
    @State private var selectedCurrency = Currency.USD
    @State private var billingCycle = BillingCycle.monthly
    @State private var startDate = Date()
    @State private var category = SubscriptionCategory.streaming
    @State private var iconName = "app.fill"
    @State private var isActive = true
    
    @State private var showingIconPicker = false
    
    private var isEditing: Bool {
        subscription != nil
    }
    
    private var title: String {
        isEditing ? "Edit Subscription" : "Add Subscription"
    }
    
    private var canSave: Bool {
        !name.isEmpty && !cost.isEmpty && Double(cost) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                billingSection
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
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $iconName)
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
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
            isActive: isActive
        )
        
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
    EditSubscriptionView(subscription: nil) { _ in }
}
import SwiftUI

struct SettingsView: View {
    @StateObject private var permissionsManager = PermissionsManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var cloudKitService = CloudKitService.shared
    @StateObject private var exchangeService = CurrencyExchangeService.shared
    @State private var showingPermissions = false
    @State private var showingAbout = false
    @State private var showingCurrencyPicker = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsRow(
                        icon: "lock.shield.fill",
                        title: "Permissions",
                        subtitle: "Manage app permissions",
                        color: .blue
                    ) {
                        showingPermissions = true
                    }
                    
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: permissionsManager.notificationStatusText,
                        color: .orange
                    ) {
                        showingPermissions = true
                    }
                } header: {
                    Text("Privacy & Permissions")
                }
                
                Section {
                    SettingsRow(
                        icon: "dollarsign.circle.fill",
                        title: "Currency",
                        subtitle: "\(currencyManager.selectedCurrency.name) (\(currencyManager.selectedCurrency.symbol))",
                        color: .green
                    ) {
                        showingCurrencyPicker = true
                    }
                } header: {
                    Text("Preferences")
                }

                // Sync Status Section
                Section {
                    // CloudKit Sync Status
                    SyncStatusRow(
                        icon: "icloud.fill",
                        title: "iCloud Sync",
                        status: cloudKitService.syncState.displayText,
                        statusColor: syncStatusColor(for: cloudKitService.syncState),
                        isLoading: cloudKitService.isLoading
                    )

                    // Exchange Rates Status
                    SyncStatusRow(
                        icon: "arrow.2.circlepath",
                        title: "Exchange Rates",
                        status: exchangeRateStatus,
                        statusColor: exchangeRateStatusColor,
                        isLoading: exchangeService.isLoading
                    )

                    // Manual refresh button
                    Button {
                        HapticManager.shared.lightImpact()
                        CloudKitService.shared.fetchSubscriptions()
                        exchangeService.forceRefresh()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Refresh All Data")
                                .foregroundColor(.primary)
                            Spacer()
                            if cloudKitService.isLoading || exchangeService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(cloudKitService.isLoading || exchangeService.isLoading)
                } header: {
                    Text("Sync Status")
                } footer: {
                    if case .failed(let error) = cloudKitService.syncState {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(error.errorDescription ?? "Unknown error")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(error.recoverySuggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if exchangeService.isStale {
                        Text("⚠️ Exchange rate data is outdated. Refresh to get current rates.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Section {
                    SettingsRow(
                        icon: "icloud.fill",
                        title: "iCloud Settings",
                        subtitle: permissionsManager.iCloudStatusText,
                        color: .blue
                    ) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                } header: {
                    Text("Data & Sync")
                }
                
                Section {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About SubTrackr",
                        subtitle: "Version 1.0",
                        color: .gray
                    ) {
                        showingAbout = true
                    }
                    
                    SettingsRow(
                        icon: "star.fill",
                        title: "Rate App",
                        subtitle: "Support development",
                        color: .yellow
                    ) {
                        if let url = URL(string: "https://apps.apple.com/app/id6738284937?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Contact Support",
                        subtitle: "Get help",
                        color: .blue
                    ) {
                        if let url = URL(string: "mailto:support@subtrackr.app?subject=SubTrackr%20Support") {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Support")
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView()
        }
    }

    // MARK: - Helper Computed Properties

    private func syncStatusColor(for state: SyncState) -> Color {
        switch state {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .failed:
            return .red
        case .offline:
            return .orange
        }
    }

    private var exchangeRateStatus: String {
        if let error = exchangeService.error {
            return error.userFriendlyMessage
        } else if exchangeService.isStale {
            return "Outdated (\(exchangeService.cacheAgeDescription))"
        } else if let lastUpdated = exchangeService.lastUpdated {
            return "Updated \(exchangeService.cacheAgeDescription)"
        } else {
            return "Never updated"
        }
    }

    private var exchangeRateStatusColor: Color {
        if exchangeService.error != nil {
            return .red
        } else if exchangeService.isStale {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Sync Status Row Component

struct SyncStatusRow: View {
    let icon: String
    let title: String
    let status: String
    let statusColor: Color
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("SubTrackr")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("SubTrackr helps you keep track of all your recurring subscriptions in one beautiful, easy-to-use app. Never miss a renewal date or lose track of your monthly spending again.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("Features:")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(text: "Calendar view of all subscriptions")
                            FeatureRow(text: "Monthly spending overview")
                            FeatureRow(text: "Search and filter subscriptions")
                            FeatureRow(text: "iCloud sync across devices")
                            FeatureRow(text: "Renewal notifications")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.regularMaterial)
                    )
                }
                .padding()
            }
            .navigationTitle("About")
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

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
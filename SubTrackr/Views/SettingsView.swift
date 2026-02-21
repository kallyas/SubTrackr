import SwiftUI

struct SettingsView: View {
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @ObservedObject private var cloudKitService = CloudKitService.shared
    @ObservedObject private var exchangeService = CurrencyExchangeService.shared
    @ObservedObject private var budgetManager = BudgetManager.shared
    @State private var showingPermissions = false
    @State private var showingAbout = false
    @State private var showingCurrencyPicker = false
    @State private var showingBudgetEditor = false
    @State private var budgetAmountText = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Preferences
                Section {
                    SettingsRow(
                        icon: "dollarsign.circle.fill",
                        title: "Currency",
                        subtitle: "\(currencyManager.selectedCurrency.name) (\(currencyManager.selectedCurrency.symbol))",
                        color: DesignSystem.Colors.success
                    ) {
                        DesignSystem.Haptics.light()
                        showingCurrencyPicker = true
                    }
                } header: {
                    Text("Preferences")
                }

                // MARK: - Budget
                Section {
                    Toggle(isOn: $budgetManager.budgetEnabled) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.warning.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "target")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(DesignSystem.Colors.warning)
                                    .symbolRenderingMode(.hierarchical)
                            }

                            Text("Budget Tracking")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.label)
                        }
                    }
                    .tint(DesignSystem.Colors.accent)

                    if budgetManager.budgetEnabled {
                        Button {
                            showingBudgetEditor = true
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.success.opacity(0.15))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(DesignSystem.Colors.success)
                                        .symbolRenderingMode(.hierarchical)
                                }

                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                    Text("Monthly Budget")
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundStyle(DesignSystem.Colors.label)

                                    Text("\(currencyManager.selectedCurrency.symbol)\(Int(budgetManager.monthlyBudget))")
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                            }
                        }
                    }
                } header: {
                    Text("Budget")
                } footer: {
                    if budgetManager.budgetEnabled {
                        Text("Get notified when you approach or exceed your monthly budget.")
                            .font(DesignSystem.Typography.caption2)
                    } else {
                        Text("Enable budget tracking to get notified when you're approaching your spending limit.")
                            .font(DesignSystem.Typography.caption2)
                    }
                }

                // MARK: - Sync Status
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
                        icon: "arrow.triangle.2.circlepath",
                        title: "Exchange Rates",
                        status: exchangeRateStatus,
                        statusColor: exchangeRateStatusColor,
                        isLoading: exchangeService.isLoading
                    )

                    // Manual refresh button
                    Button {
                        DesignSystem.Haptics.medium()
                        CloudKitService.shared.fetchSubscriptions()
                        exchangeService.forceRefresh()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.accent.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(DesignSystem.Colors.accent)
                                    .symbolRenderingMode(.hierarchical)
                            }

                            Text("Refresh All Data")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.label)

                            Spacer()

                            if cloudKitService.isLoading || exchangeService.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(cloudKitService.isLoading || exchangeService.isLoading)
                } header: {
                    Text("Sync Status")
                } footer: {
                    if case .failed(let error) = cloudKitService.syncState {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Label {
                                Text(error.errorDescription ?? "Unknown error")
                                    .font(DesignSystem.Typography.caption1)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(DesignSystem.Colors.error)
                            }

                            Text(error.recoverySuggestion)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                    } else if exchangeService.isStale {
                        Label {
                            Text("Exchange rate data is outdated. Tap refresh to update.")
                                .font(DesignSystem.Typography.caption1)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(DesignSystem.Colors.warning)
                        }
                    }
                }

                // MARK: - Privacy & Permissions
                Section {
                    SettingsRow(
                        icon: "hand.raised.fill",
                        title: "Permissions",
                        subtitle: "Manage app permissions",
                        color: Color(red: 0.0, green: 0.48, blue: 1.0)
                    ) {
                        DesignSystem.Haptics.light()
                        showingPermissions = true
                    }

                    SettingsRow(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        subtitle: permissionsManager.notificationStatusText,
                        color: DesignSystem.Colors.error
                    ) {
                        DesignSystem.Haptics.light()
                        showingPermissions = true
                    }

                    SettingsRow(
                        icon: "icloud.fill",
                        title: "iCloud",
                        subtitle: permissionsManager.iCloudStatusText,
                        color: Color(red: 0.0, green: 0.48, blue: 1.0)
                    ) {
                        DesignSystem.Haptics.light()
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                } header: {
                    Text("Privacy & Permissions")
                }

                // MARK: - Support
                Section {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About SubTrackr",
                        subtitle: "Version 1.0.0",
                        color: Color(UIColor.systemGray)
                    ) {
                        DesignSystem.Haptics.light()
                        showingAbout = true
                    }

                    SettingsRow(
                        icon: "star.fill",
                        title: "Rate on App Store",
                        subtitle: "Support development",
                        color: Color(red: 1.0, green: 0.8, blue: 0.0)
                    ) {
                        DesignSystem.Haptics.light()
                        if let url = URL(string: "https://apps.apple.com/app/id6738284937?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }

                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Contact Support",
                        subtitle: "support@subtrackr.app",
                        color: Color(red: 0.0, green: 0.48, blue: 1.0)
                    ) {
                        DesignSystem.Haptics.light()
                        if let url = URL(string: "mailto:support@subtrackr.app?subject=SubTrackr%20Support") {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("About & Support")
                }
            }
            .listStyle(.insetGrouped)
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
        .sheet(isPresented: $showingBudgetEditor) {
            BudgetEditorView()
        }
    }

    // MARK: - Helper Functions

    private func syncStatusColor(for state: SyncState) -> Color {
        switch state {
        case .idle:
            return DesignSystem.Colors.tertiaryLabel
        case .syncing:
            return DesignSystem.Colors.info
        case .synced:
            return DesignSystem.Colors.success
        case .failed:
            return DesignSystem.Colors.error
        case .offline:
            return DesignSystem.Colors.warning
        }
    }

    private var exchangeRateStatus: String {
        if let error = exchangeService.error {
            return error.userFriendlyMessage
        } else if exchangeService.isStale {
            return "Outdated (\(exchangeService.cacheAgeDescription))"
        } else if let _ = exchangeService.lastUpdated {
            return "Updated \(exchangeService.cacheAgeDescription)"
        } else {
            return "Never updated"
        }
    }

    private var exchangeRateStatusColor: Color {
        if exchangeService.error != nil {
            return DesignSystem.Colors.error
        } else if exchangeService.isStale {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.success
        }
    }
}

// MARK: - Sync Status Row

struct SyncStatusRow: View {
    let icon: String
    let title: String
    let status: String
    let statusColor: Color
    let isLoading: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.label)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(status)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }
            }

            Spacer()

            if isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(color)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text(subtitle)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxxl) {
                    // App Icon & Title
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // App Icon
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.accent,
                                        DesignSystem.Colors.accent.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .symbolRenderingMode(.hierarchical)
                            )
                            .softShadow()

                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text("SubTrackr")
                                .font(DesignSystem.Typography.largeTitleRounded)

                            Text("Version 1.0.0")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xxl)

                    // About Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("About")
                                .font(DesignSystem.Typography.title3)

                            Text("SubTrackr helps you keep track of all your recurring subscriptions in one beautiful, easy-to-use app. Never miss a renewal date or lose track of your monthly spending again.")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                            .padding(.vertical, DesignSystem.Spacing.sm)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Features")
                                .font(DesignSystem.Typography.title3)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                FeatureRow(icon: "calendar", text: "Calendar view of all subscriptions")
                                FeatureRow(icon: "chart.pie.fill", text: "Monthly spending overview")
                                FeatureRow(icon: "magnifyingglass", text: "Search and filter subscriptions")
                                FeatureRow(icon: "icloud.fill", text: "iCloud sync across devices")
                                FeatureRow(icon: "bell.fill", text: "Renewal notifications")
                                FeatureRow(icon: "dollarsign.circle.fill", text: "Multi-currency support")
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                            .fill(DesignSystem.Colors.secondaryBackground)
                    )
                    .screenPadding()
                }
                .padding(.bottom, DesignSystem.Spacing.xxxl)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        DesignSystem.Haptics.light()
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.success)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(text)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.label)
        }
    }
}

#Preview {
    SettingsView()
}

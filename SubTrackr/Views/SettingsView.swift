import SwiftUI

struct SettingsView: View {
    @StateObject private var permissionsManager = PermissionsManager.shared
    @State private var showingPermissions = false
    @State private var showingAbout = false
    
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
                        icon: "icloud.fill",
                        title: "iCloud Sync",
                        subtitle: permissionsManager.iCloudStatusText,
                        color: .blue
                    ) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    
                    SettingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Refresh Data",
                        subtitle: "Sync with iCloud",
                        color: .green
                    ) {
                        HapticManager.shared.lightImpact()
                        CloudKitService.shared.fetchSubscriptions()
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
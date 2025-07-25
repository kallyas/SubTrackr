import SwiftUI

struct PermissionsView: View {
    @StateObject private var permissionsManager = PermissionsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    notificationPermissionCard
                    iCloudPermissionCard
                    infoSection
                }
                .padding()
            }
            .navigationTitle("Permissions")
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
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("App Permissions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("SubTrackr needs these permissions to provide the best experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var notificationPermissionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(.headline)
                    
                    Text("Get reminders for upcoming subscription renewals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(
                    text: permissionsManager.notificationStatusText,
                    color: permissionsManager.notificationStatusColor
                )
            }
            
            if permissionsManager.notificationPermissionStatus == .notDetermined {
                Button {
                    Task {
                        await permissionsManager.requestNotificationPermissions()
                    }
                } label: {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else if permissionsManager.notificationPermissionStatus == .denied {
                Button {
                    permissionsManager.openiCloudSettings()
                } label: {
                    Text("Open Settings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
    
    private var iCloudPermissionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "icloud.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(.headline)
                    
                    Text("Sync your subscriptions across all your Apple devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(
                    text: permissionsManager.iCloudStatusText,
                    color: permissionsManager.iCloudStatusColor
                )
            }
            
            if permissionsManager.iCloudStatus != .available {
                Button {
                    permissionsManager.openiCloudSettings()
                } label: {
                    Text("Check iCloud Settings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why These Permissions?")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                PermissionInfoRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "We'll remind you before subscriptions renew so you can cancel if needed."
                )
                
                PermissionInfoRow(
                    icon: "icloud.fill",
                    title: "iCloud Sync",
                    description: "Your subscription data stays in sync across iPhone, iPad, and Mac."
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct PermissionInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    PermissionsView()
}
import Foundation
import SwiftUI
import UserNotifications
import CloudKit
import UIKit

class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var iCloudStatus: CKAccountStatus = .couldNotDetermine
    
    private init() {
        checkNotificationPermissions()
        checkiCloudStatus()
    }
    
    // MARK: - Notification Permissions
    
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.notificationPermissionStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            return false
        }
    }
    
    // MARK: - iCloud Permissions
    
    func checkiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudStatus = status
            }

            // Silently handle error
            _ = error
        }
    }
    
    func openiCloudSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    // MARK: - Permission Status Text
    
    var notificationStatusText: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "Notifications Enabled"
        case .denied:
            return "Notifications Disabled"
        case .notDetermined:
            return "Notifications Not Requested"
        case .provisional:
            return "Provisional Notifications"
        case .ephemeral:
            return "Ephemeral Notifications"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    var iCloudStatusText: String {
        switch iCloudStatus {
        case .available:
            return "iCloud Available"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "iCloud Status Unknown"
        case .temporarilyUnavailable:
            return "iCloud Temporarily Unavailable"
        @unknown default:
            return "Unknown iCloud Status"
        }
    }
    
    var notificationStatusColor: Color {
        switch notificationPermissionStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        default: return .gray
        }
    }
    
    var iCloudStatusColor: Color {
        switch iCloudStatus {
        case .available: return .green
        case .noAccount, .restricted: return .gray
        case .couldNotDetermine: return .orange
        case .temporarilyUnavailable: return .red
        @unknown default: return .gray
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleRenewalNotification(for subscription: Subscription) {
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewal"
        content.body = "\(subscription.name) renews today for \(subscription.formattedCost)"
        content.sound = .default
        content.badge = 1
        
        // Create date components for the next billing date
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour], from: subscription.nextBillingDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "renewal-\(subscription.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            // Silently handle error
            _ = error
        }
    }
    
    func cancelNotification(for subscriptionId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["renewal-\(subscriptionId)"]
        )
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

import Foundation
import UserNotifications
import SwiftUI

/// Manages local notifications for subscription reminders
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var settings: UNNotificationSettings?

    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                self.settings = settings
            }
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule notifications for a subscription
    func scheduleNotifications(for subscription: Subscription) async {
        guard isAuthorized else {
            return
        }

        // Cancel existing notifications for this subscription
        await cancelNotifications(for: subscription)

        // Schedule renewal reminder (1 day before)
        await scheduleRenewalReminder(for: subscription, daysBefore: 1)

        // Schedule renewal reminder (3 days before) for expensive subscriptions
        if subscription.cost > 50 {
            await scheduleRenewalReminder(for: subscription, daysBefore: 3)
        }

        // Schedule renewal reminder (7 days before) for very expensive subscriptions
        if subscription.cost > 100 {
            await scheduleRenewalReminder(for: subscription, daysBefore: 7)
        }
    }

    private func scheduleRenewalReminder(for subscription: Subscription, daysBefore: Int) async {
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: subscription.nextBillingDate) else {
            return
        }

        // Only schedule if the reminder date is in the future
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Renewal"

        if daysBefore == 1 {
            content.body = "\(subscription.name) renews tomorrow for \(subscription.formattedCost)"
        } else {
            content.body = "\(subscription.name) renews in \(daysBefore) days for \(subscription.formattedCost)"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SUBSCRIPTION_RENEWAL"
        content.userInfo = [
            "subscriptionId": subscription.id,
            "subscriptionName": subscription.name,
            "renewalDate": subscription.nextBillingDate.timeIntervalSince1970
        ]

        // Set up date components for the notification
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "renewal-\(subscription.id)-\(daysBefore)d"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silently fail
        }
    }

    /// Schedule a notification for free trial expiration
    func scheduleFreeTrialReminder(for subscription: Subscription, expirationDate: Date) async {
        guard isAuthorized else { return }

        let calendar = Calendar.current

        // Schedule 3 days before expiration
        if let reminderDate = calendar.date(byAdding: .day, value: -3, to: expirationDate),
           reminderDate > Date() {

            let content = UNMutableNotificationContent()
            content.title = "Free Trial Ending Soon"
            content.body = "Your \(subscription.name) free trial expires in 3 days. Cancel now to avoid being charged \(subscription.formattedCost)."
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "FREE_TRIAL_EXPIRING"
            content.userInfo = [
                "subscriptionId": subscription.id,
                "subscriptionName": subscription.name,
                "expirationDate": expirationDate.timeIntervalSince1970
            ]

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let identifier = "free-trial-\(subscription.id)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await UNUserNotificationCenter.current().add(request)
        }

        // Schedule 1 day before expiration
        if let reminderDate = calendar.date(byAdding: .day, value: -1, to: expirationDate),
           reminderDate > Date() {

            let content = UNMutableNotificationContent()
            content.title = "⚠️ Free Trial Ends Tomorrow"
            content.body = "Your \(subscription.name) free trial expires tomorrow! Cancel today or you'll be charged \(subscription.formattedCost)."
            content.sound = .defaultCritical
            content.badge = 1
            content.categoryIdentifier = "FREE_TRIAL_EXPIRING"

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let identifier = "free-trial-urgent-\(subscription.id)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// Schedule budget warning notification
    func scheduleBudgetWarning(currentSpending: Double, budget: Double) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Budget Alert"
        content.body = "You've reached \(Int((currentSpending / budget) * 100))% of your monthly budget!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BUDGET_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "budget-warning-\(UUID().uuidString)", content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Schedule price increase notification
    func schedulePriceIncreaseNotification(for subscription: Subscription, oldPrice: Double, newPrice: Double) async {
        guard isAuthorized else { return }
        
        let priceIncrease = newPrice - oldPrice
        let percentageIncrease = Int((priceIncrease / oldPrice) * 100)
        
        let content = UNMutableNotificationContent()
        content.title = "📈 Price Increase Alert"
        content.body = "\(subscription.name) price increased by \(percentageIncrease)% (\(subscription.currency.formatAmount(priceIncrease))/\(subscription.billingCycle.rawValue.lowercased()))"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "PRICE_INCREASE"
        content.userInfo = [
            "subscriptionId": subscription.id,
            "subscriptionName": subscription.name,
            "oldPrice": oldPrice,
            "newPrice": newPrice,
            "priceIncrease": priceIncrease
        ]
        
        // Send immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "price-increase-\(subscription.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Check for price increases in subscriptions
    func checkForPriceIncreases(subscriptions: [Subscription]) async {
        guard isAuthorized else { return }
        
        for subscription in subscriptions where subscription.hasPriceIncreased {
            if let latestChange = subscription.latestPriceChange,
               let previousPrice = latestChange.previousPrice,
               latestChange.isIncrease {
                await schedulePriceIncreaseNotification(
                    for: subscription,
                    oldPrice: previousPrice,
                    newPrice: latestChange.price
                )
            }
        }
    }

    // MARK: - Cancel Notifications

    func cancelNotifications(for subscription: Subscription) async {
        let identifiers = [
            "renewal-\(subscription.id)-1d",
            "renewal-\(subscription.id)-3d",
            "renewal-\(subscription.id)-7d",
            "free-trial-\(subscription.id)",
            "free-trial-urgent-\(subscription.id)"
        ]

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - Notification Actions

    func setupNotificationCategories() {
        // Renewal category with actions
        let renewalCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION_RENEWAL",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_SUBSCRIPTION",
                    title: "View Details",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "SNOOZE_REMINDER",
                    title: "Remind Tomorrow",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        // Free trial category with actions
        let freeTrialCategory = UNNotificationCategory(
            identifier: "FREE_TRIAL_EXPIRING",
            actions: [
                UNNotificationAction(
                    identifier: "CANCEL_SUBSCRIPTION",
                    title: "Cancel Now",
                    options: [.destructive, .foreground]
                ),
                UNNotificationAction(
                    identifier: "VIEW_SUBSCRIPTION",
                    title: "View Details",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        // Budget warning category
        let budgetCategory = UNNotificationCategory(
            identifier: "BUDGET_WARNING",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_OVERVIEW",
                    title: "View Overview",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            renewalCategory,
            freeTrialCategory,
            budgetCategory
        ])
    }

    // MARK: - Helper Methods

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return await UNUserNotificationCenter.current().deliveredNotifications()
    }

    /// Test notification for debugging
    func sendTestNotification() async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎉 Test Notification"
        content.body = "SubTrackr notifications are working perfectly!"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "VIEW_SUBSCRIPTION":
            // Navigate to subscription details
            if let subscriptionId = userInfo["subscriptionId"] as? String {
                NotificationCenter.default.post(
                    name: .openSubscription,
                    object: nil,
                    userInfo: ["subscriptionId": subscriptionId]
                )
            }

        case "SNOOZE_REMINDER":
            // Reschedule for tomorrow
            break

        case "CANCEL_SUBSCRIPTION":
            // Open subscription to cancel
            if let subscriptionId = userInfo["subscriptionId"] as? String {
                NotificationCenter.default.post(
                    name: .cancelSubscription,
                    object: nil,
                    userInfo: ["subscriptionId": subscriptionId]
                )
            }

        case "VIEW_OVERVIEW":
            // Navigate to overview tab
            NotificationCenter.default.post(name: .openOverview, object: nil)

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSubscription = Notification.Name("openSubscription")
    static let cancelSubscription = Notification.Name("cancelSubscription")
    static let openOverview = Notification.Name("openOverview")
}

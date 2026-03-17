import Foundation
import ActivityKit
import SwiftUI
import WidgetShared

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var activeActivity: Activity<SubscriptionLiveActivityAttributes>?
    
    private init() {}
    
    func startActivity(for subscription: Subscription) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled.")
            return
        }
        
        let hexColor = subscription.category.color.toHex() ?? "#000000"
        
        let attributes = SubscriptionLiveActivityAttributes(
            subscriptionId: subscription.id,
            subscriptionName: subscription.name,
            subscriptionCost: subscription.formattedCost,
            iconName: subscription.category.iconName,
            categoryColor: hexColor
        )
        
        let contentState = makeContentState(for: subscription)
        
        do {
            let activity = try Activity<SubscriptionLiveActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            DispatchQueue.main.async {
                self.activeActivity = activity
            }
            print("Requested Live Activity with id: \(activity.id)")
        } catch {
            print("Error requesting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(for subscription: Subscription) {
        guard let activity = activeActivity else { return }
        
        let contentState = makeContentState(for: subscription)
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func endActivity() {
        guard let activity = activeActivity else { return }
        let contentState = activity.content.state
        
        Task {
            await activity.end(.init(state: contentState, staleDate: nil), dismissalPolicy: .immediate)
            DispatchQueue.main.async {
                self.activeActivity = nil
            }
        }
    }

    private func makeContentState(for subscription: Subscription) -> SubscriptionLiveActivityAttributes.ContentState {
        let relatedSubscriptions = upcomingRelatedSubscriptions(for: subscription)

        return SubscriptionLiveActivityAttributes.ContentState(
            nextBillingDate: subscription.nextBillingDate,
            additionalSubscriptionsCount: relatedSubscriptions.count,
            relatedSubscriptions: Array(relatedSubscriptions.prefix(3))
        )
    }

    private func upcomingRelatedSubscriptions(for subscription: Subscription) -> [RelatedSubscription] {
        guard let widgetData = WidgetDataManager.shared.loadWidgetData() else {
            return []
        }

        return widgetData.upcomingRenewals
            .filter { $0.id != subscription.id }
            .map {
                RelatedSubscription(
                    id: $0.id,
                    name: $0.name,
                    cost: $0.formattedCost,
                    billingDate: $0.nextBillingDate
                )
            }
    }
}

// Helper extension to convert Color to Hex string for the widget
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

import UIKit
import SwiftUI

/// Manages 3D Touch / Haptic Touch Quick Actions from home screen
class QuickActionsManager {
    static let shared = QuickActionsManager()

    enum QuickActionType: String {
        case addSubscription = "com.subtrackr.add"
        case viewCalendar = "com.subtrackr.calendar"
        case viewOverview = "com.subtrackr.overview"
        case viewUpcoming = "com.subtrackr.upcoming"

        var icon: UIApplicationShortcutIcon {
            switch self {
            case .addSubscription:
                return UIApplicationShortcutIcon(systemImageName: "plus.circle.fill")
            case .viewCalendar:
                return UIApplicationShortcutIcon(systemImageName: "calendar")
            case .viewOverview:
                return UIApplicationShortcutIcon(systemImageName: "chart.pie.fill")
            case .viewUpcoming:
                return UIApplicationShortcutIcon(systemImageName: "clock.fill")
            }
        }

        var title: String {
            switch self {
            case .addSubscription: return "Add Subscription"
            case .viewCalendar: return "View Calendar"
            case .viewOverview: return "Monthly Overview"
            case .viewUpcoming: return "Upcoming Renewals"
            }
        }
    }

    private init() {}

    func setupQuickActions() {
        let quickActions: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: QuickActionType.addSubscription.rawValue,
                localizedTitle: QuickActionType.addSubscription.title,
                localizedSubtitle: "Track a new subscription",
                icon: QuickActionType.addSubscription.icon,
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.viewOverview.rawValue,
                localizedTitle: QuickActionType.viewOverview.title,
                localizedSubtitle: "See your spending",
                icon: QuickActionType.viewOverview.icon,
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.viewCalendar.rawValue,
                localizedTitle: QuickActionType.viewCalendar.title,
                localizedSubtitle: "Check renewal dates",
                icon: QuickActionType.viewCalendar.icon,
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.viewUpcoming.rawValue,
                localizedTitle: QuickActionType.viewUpcoming.title,
                localizedSubtitle: "Next 7 days",
                icon: QuickActionType.viewUpcoming.icon,
                userInfo: nil
            )
        ]

        UIApplication.shared.shortcutItems = quickActions
    }

    func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> QuickActionType? {
        return QuickActionType(rawValue: shortcutItem.type)
    }
}


 */

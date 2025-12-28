//
//  EmptyStateView.swift
//  SubTrackr
//
//  Reusable empty state component with illustrations and CTAs
//

import SwiftUI

struct EmptyStateView: View {
    let variant: EmptyStateVariant
    let compact: Bool

    init(variant: EmptyStateVariant, compact: Bool = false) {
        self.variant = variant
        self.compact = compact
    }

    // Legacy init for backward compatibility
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.variant = .custom(icon: icon, title: title, description: description, actionTitle: actionTitle, action: action)
        self.compact = false
    }

    var body: some View {
        VStack(spacing: compact ? DesignSystem.Spacing.lg : DesignSystem.Spacing.xl) {
            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primarySubtle)
                    .frame(width: compact ? 80 : 120, height: compact ? 80 : 120)

                Image(systemName: variant.icon)
                    .font(.system(size: compact ? 36 : 50, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(variant.title)
                    .font(compact ? DesignSystem.Typography.headline : DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text(variant.description)
                    .font(compact ? DesignSystem.Typography.subheadline : DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, compact ? DesignSystem.Spacing.lg : DesignSystem.Spacing.xl)
            }

            if let actionTitle = variant.actionTitle, let action = variant.action {
                Button(action: {
                    DesignSystem.Haptics.light()
                    action()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                        Text(actionTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(compact ? DesignSystem.Spacing.lg : DesignSystem.Spacing.xxl)
    }
}

// MARK: - Empty State Variant

enum EmptyStateVariant {
    case noSubscriptions
    case noSearchResults
    case noSubscriptionsToday
    case noUpcomingRenewals
    case noCategorySubscriptions
    case syncError
    case custom(icon: String, title: String, description: String, actionTitle: String?, action: (() -> Void)?)

    var icon: String {
        switch self {
        case .noSubscriptions: return "creditcard.and.123"
        case .noSearchResults: return "magnifyingglass"
        case .noSubscriptionsToday: return "calendar"
        case .noUpcomingRenewals: return "checkmark.circle.fill"
        case .noCategorySubscriptions: return "folder"
        case .syncError: return "exclamationmark.icloud.fill"
        case .custom(let icon, _, _, _, _): return icon
        }
    }

    var title: String {
        switch self {
        case .noSubscriptions: return "No Subscriptions Yet"
        case .noSearchResults: return "No Results Found"
        case .noSubscriptionsToday: return "No Renewals Today"
        case .noUpcomingRenewals: return "All Clear!"
        case .noCategorySubscriptions: return "No Subscriptions"
        case .syncError: return "Sync Failed"
        case .custom(_, let title, _, _, _): return title
        }
    }

    var description: String {
        switch self {
        case .noSubscriptions:
            return "Start tracking your subscriptions to see your monthly spending and upcoming renewals."
        case .noSearchResults:
            return "Try adjusting your search or filters to find what you're looking for."
        case .noSubscriptionsToday:
            return "You don't have any subscriptions renewing on this date."
        case .noUpcomingRenewals:
            return "You don't have any subscriptions renewing in the next 7 days."
        case .noCategorySubscriptions:
            return "You don't have any subscriptions in this category yet."
        case .syncError:
            return "Unable to sync with iCloud. Check your connection and try again."
        case .custom(_, _, let description, _, _):
            return description
        }
    }

    var actionTitle: String? {
        switch self {
        case .noSubscriptions: return "Add First Subscription"
        case .syncError: return "Retry"
        case .custom(_, _, _, let actionTitle, _): return actionTitle
        default: return nil
        }
    }

    var action: (() -> Void)? {
        switch self {
        case .custom(_, _, _, _, let action): return action
        default: return nil
        }
    }
}

// MARK: - Predefined Empty States (Legacy Support)

extension EmptyStateView {
    /// Empty state for no subscriptions
    static func noSubscriptions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            variant: .custom(
                icon: "creditcard.and.123",
                title: "No Subscriptions Yet",
                description: "Start tracking your subscriptions to see your monthly spending and upcoming renewals.",
                actionTitle: "Add First Subscription",
                action: action
            )
        )
    }

    /// Empty state for no search results
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(variant: .noSearchResults)
    }

    /// Empty state for calendar with no subscriptions on selected day
    static func noSubscriptionsToday() -> EmptyStateView {
        EmptyStateView(variant: .noSubscriptionsToday)
    }

    /// Empty state for upcoming renewals
    static func noUpcomingRenewals() -> EmptyStateView {
        EmptyStateView(variant: .noUpcomingRenewals)
    }

    /// Empty state for category with no subscriptions
    static func noCategorySubscriptions(category: String) -> EmptyStateView {
        EmptyStateView(
            variant: .custom(
                icon: "folder",
                title: "No \(category) Subscriptions",
                description: "You don't have any subscriptions in this category yet.",
                actionTitle: nil,
                action: nil
            )
        )
    }

    /// Empty state for offline/sync failure
    static func syncError(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            variant: .custom(
                icon: "exclamationmark.icloud.fill",
                title: "Sync Failed",
                description: "Unable to sync with iCloud. Check your connection and try again.",
                actionTitle: "Retry",
                action: action
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            EmptyStateView(variant: .noSubscriptions)

            Divider()

            EmptyStateView(variant: .noSearchResults, compact: true)

            Divider()

            EmptyStateView(variant: .noUpcomingRenewals)
        }
        .padding()
    }
}

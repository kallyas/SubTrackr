//
//  EmptyStateView.swift
//  SubTrackr
//
//  Reusable empty state component with illustrations and CTAs
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryLight)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xxl)
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    /// Empty state for no subscriptions
    static func noSubscriptions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "creditcard.and.123",
            title: "No Subscriptions Yet",
            description: "Start tracking your subscriptions to see your monthly spending and upcoming renewals.",
            actionTitle: "Add First Subscription",
            action: action
        )
    }

    /// Empty state for no search results
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            description: "Try adjusting your search or filters to find what you're looking for."
        )
    }

    /// Empty state for calendar with no subscriptions on selected day
    static func noSubscriptionsToday() -> EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "No Renewals Today",
            description: "You don't have any subscriptions renewing on this date."
        )
    }

    /// Empty state for upcoming renewals
    static func noUpcomingRenewals() -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All Clear!",
            description: "You don't have any subscriptions renewing in the next 7 days."
        )
    }

    /// Empty state for category with no subscriptions
    static func noCategorySubscriptions(category: String) -> EmptyStateView {
        EmptyStateView(
            icon: "folder",
            title: "No \(category) Subscriptions",
            description: "You don't have any subscriptions in this category yet."
        )
    }

    /// Empty state for offline/sync failure
    static func syncError(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.icloud",
            title: "Sync Failed",
            description: "Unable to sync with iCloud. Check your connection and try again.",
            actionTitle: "Retry",
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmptyStateView.noSubscriptions(action: {})

        Divider()

        EmptyStateView.noSearchResults()
    }
}

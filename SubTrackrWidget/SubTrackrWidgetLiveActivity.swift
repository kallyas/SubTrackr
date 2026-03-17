//
//  SubTrackrWidgetLiveActivity.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import WidgetShared

struct SubTrackrWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SubscriptionLiveActivityAttributes.self) { context in
            let accentColor = Color(hex: context.attributes.categoryColor)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 50, height: 50)

                    Image(systemName: context.attributes.iconName)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(context.attributes.subscriptionName)
                            .font(.headline)
                            .lineLimit(1)

                        Text(context.state.statusLabel)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(context.state.statusColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(context.state.statusColor.opacity(0.16), in: Capsule())
                    }

                    Text(context.state.primaryMessage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(context.state.secondaryMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.attributes.subscriptionCost)
                        .font(.headline)
                        .fontWeight(.bold)
                        .monospacedDigit()

                    Text(context.state.trailingDetail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color.black.opacity(0.86))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Image(systemName: context.attributes.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(hex: context.attributes.categoryColor))
                                .symbolRenderingMode(.hierarchical)

                            Text(context.attributes.subscriptionName)
                                .font(.headline)
                                .lineLimit(1)
                        }

                        if context.state.hasAdditionalSubscriptions {
                            Text(context.state.collectionSummary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.subscriptionCost)
                            .font(.headline)
                            .fontWeight(.bold)
                            .monospacedDigit()

                        Text(context.state.shortStatusLabel)
                            .font(.caption2)
                            .foregroundStyle(context.state.statusColor)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(context.state.primaryMessage)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 6) {
                            Image(systemName: context.state.statusIconName)
                                .font(.caption)
                                .foregroundStyle(context.state.statusColor)

                            Text(context.state.secondaryMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if context.state.hasAdditionalSubscriptions {
                            Divider()
                                .overlay(.white.opacity(0.08))

                            VStack(alignment: .leading, spacing: 8) {
                                Text(context.state.previewHeader)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                ForEach(context.state.relatedSubscriptions.prefix(2)) { subscription in
                                    HStack(spacing: 8) {
                                        Text(subscription.name)
                                            .font(.caption)
                                            .lineLimit(1)

                                        Spacer(minLength: 8)

                                        Text(subscription.billingDate.relativeBillingLabel)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)

                                        Text(subscription.cost)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .monospacedDigit()
                                    }
                                }

                                if context.state.additionalSubscriptionsCount > context.state.relatedSubscriptions.prefix(2).count {
                                    Text(context.state.remainingSubscriptionsLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Text(context.state.compactStatusLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.statusColor)
                        .monospacedDigit()

                    if context.state.hasAdditionalSubscriptions {
                        Text("+\(context.state.additionalSubscriptionsCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactTrailing: {
                Text(context.attributes.subscriptionCost)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.attributes.iconName)
                    .foregroundStyle(Color(hex: context.attributes.categoryColor))
                    .symbolRenderingMode(.hierarchical)
            }
            .widgetURL(URL(string: "subtrackr://subscription/\(context.attributes.subscriptionId)"))
            .keylineTint(Color(hex: context.attributes.categoryColor))
        }
    }
}

// Helper for Hex Colors inside the Widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
extension SubscriptionLiveActivityAttributes {
    fileprivate static var preview: SubscriptionLiveActivityAttributes {
        SubscriptionLiveActivityAttributes(
            subscriptionId: "1",
            subscriptionName: "Netflix",
            subscriptionCost: "$15.99",
            iconName: "tv.fill",
            categoryColor: "FF0000" // Red for Streaming
        )
    }
}

extension SubscriptionLiveActivityAttributes.ContentState {
    fileprivate var hasAdditionalSubscriptions: Bool {
        additionalSubscriptionsCount > 0
    }

    fileprivate var daysUntilBilling: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let billingDate = calendar.startOfDay(for: nextBillingDate)
        return calendar.dateComponents([.day], from: today, to: billingDate).day ?? 0
    }

    fileprivate var statusLabel: String {
        switch daysUntilBilling {
        case ...0: return "Due"
        case 1: return "Tomorrow"
        case 2...6: return "Soon"
        default: return "Upcoming"
        }
    }

    fileprivate var shortStatusLabel: String {
        switch daysUntilBilling {
        case ...0: return "Due now"
        case 1: return "Tomorrow"
        default: return "In \(daysUntilBilling)d"
        }
    }

    fileprivate var compactStatusLabel: String {
        switch daysUntilBilling {
        case ...0: return "Now"
        case 1: return "1d"
        default: return "\(daysUntilBilling)d"
        }
    }

    fileprivate var primaryMessage: String {
        switch daysUntilBilling {
        case ..<0:
            return "Renewed \(abs(daysUntilBilling)) day\(abs(daysUntilBilling) == 1 ? "" : "s") ago"
        case 0:
            return "Renews today"
        case 1:
            return "Renews tomorrow"
        default:
            return "Renews in \(daysUntilBilling) days"
        }
    }

    fileprivate var secondaryMessage: String {
        "Billing date: \(nextBillingDate.formatted(date: .complete, time: .omitted))"
    }

    fileprivate var trailingDetail: String {
        hasAdditionalSubscriptions ? collectionSummary : "per renewal"
    }

    fileprivate var collectionSummary: String {
        if additionalSubscriptionsCount == 1 {
            return "1 more renewal coming up"
        }

        return "\(additionalSubscriptionsCount) more renewals coming up"
    }

    fileprivate var previewHeader: String {
        if additionalSubscriptionsCount == 1 {
            return "Also coming up"
        }

        return "Other upcoming renewals"
    }

    fileprivate var remainingSubscriptionsLabel: String {
        let hiddenCount = additionalSubscriptionsCount - relatedSubscriptions.prefix(2).count
        guard hiddenCount > 0 else { return "" }

        if hiddenCount == 1 {
            return "+1 more renewal"
        }

        return "+\(hiddenCount) more renewals"
    }

    fileprivate var statusIconName: String {
        switch daysUntilBilling {
        case ...0: return "exclamationmark.circle.fill"
        case 1: return "clock.badge.exclamationmark.fill"
        default: return "calendar"
        }
    }

    fileprivate var statusColor: Color {
        switch daysUntilBilling {
        case ...0: return .red
        case 1: return .orange
        default: return .secondary
        }
    }

    fileprivate static var thisWeek: SubscriptionLiveActivityAttributes.ContentState {
        SubscriptionLiveActivityAttributes.ContentState(
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            additionalSubscriptionsCount: 2,
            relatedSubscriptions: [
                RelatedSubscription(
                    id: "2",
                    name: "Spotify",
                    cost: "$9.99",
                    billingDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!
                ),
                RelatedSubscription(
                    id: "3",
                    name: "iCloud+",
                    cost: "$2.99",
                    billingDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                )
            ]
        )
    }
     
    fileprivate static var tomorrow: SubscriptionLiveActivityAttributes.ContentState {
        SubscriptionLiveActivityAttributes.ContentState(
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
    }
}

extension Date {
    fileprivate var relativeBillingLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let billingDate = calendar.startOfDay(for: self)
        let dayCount = calendar.dateComponents([.day], from: today, to: billingDate).day ?? 0

        switch dayCount {
        case ..<0:
            return "\(abs(dayCount))d ago"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return "In \(dayCount)d"
        }
    }
}

#Preview("Live Activity", as: .dynamicIsland(.expanded), using: SubscriptionLiveActivityAttributes.preview) {
   SubTrackrWidgetLiveActivity()
} contentStates: {
    SubscriptionLiveActivityAttributes.ContentState.thisWeek
    SubscriptionLiveActivityAttributes.ContentState.tomorrow
}

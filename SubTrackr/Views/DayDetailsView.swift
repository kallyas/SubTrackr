import SwiftUI

struct DayDetailsView: View {
    let date: Date
    let subscriptions: [Subscription]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingDeleteAlert = false
    @State private var subscriptionToDelete: Subscription?
    @State private var dragOffset: CGFloat = 0

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let titleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var totalCost: Double {
        subscriptions.reduce(0) { total, subscription in
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            return total + convertedCost
        }
    }

    private var activeTrialsCount: Int {
        subscriptions.filter(\.isTrial).count
    }

    private var sharedSubscriptionsCount: Int {
        subscriptions.filter(\.isSharedSubscription).count
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }

    private var dateTitle: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            return Self.titleDateFormatter.string(from: date)
        }
    }

    private var dateContextLine: String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfSelected = calendar.startOfDay(for: date)
        let dayOffset = calendar.dateComponents([.day], from: startOfToday, to: startOfSelected).day ?? 0

        if dayOffset == 0 {
            return "Renewing today"
        }
        if dayOffset == 1 {
            return "Coming up tomorrow"
        }
        if dayOffset == -1 {
            return "Renewals from yesterday"
        }
        if dayOffset > 1 {
            return "In \(dayOffset) days"
        }
        return "\(abs(dayOffset)) days ago"
    }

    private var bodyCopy: String {
        if subscriptions.isEmpty {
            return "Nothing renews on this date."
        }

        let renewalLabel = subscriptions.count == 1 ? "renewal" : "renewals"
        return "\(subscriptions.count) \(renewalLabel) totalling \(currencyManager.formatAmount(totalCost))"
    }

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Colors.groupedBackground
            .ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator
                scrollContent
            }
            .offset(y: dragOffset)
            .gesture(dismissGesture)
        }
        .alert("Delete Subscription", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }

            if let subscription = subscriptionToDelete {
                Button("Manage Subscription") {
                    SubscriptionURLProvider.openCancellationURL(for: subscription.name)
                }
            }

            Button("Delete from App", role: .destructive) {
                if let subscription = subscriptionToDelete {
                    subscriptionViewModel.deleteSubscription(subscription)
                    dismiss()
                }
            }
        } message: {
            if let subscription = subscriptionToDelete {
                Text("Before deleting '\(subscription.name)' from the app, you may want to cancel it with the service provider first to avoid future charges.")
            } else {
                Text("Are you sure you want to delete this subscription?")
            }
        }
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 110 {
                    dismiss()
                } else {
                    withAnimation(DesignSystem.Animation.springSmooth) {
                        dragOffset = 0
                    }
                }
            }
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(DesignSystem.Colors.secondaryLabel.opacity(0.45))
            .frame(width: 36, height: 5)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.md)
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                heroCard

                if subscriptions.isEmpty {
                    emptyStateCard
                } else {
                    if !summaryMetrics.isEmpty {
                        metricsGrid
                    }

                    renewalsSection
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.xs)
            .padding(.bottom, DesignSystem.Spacing.xxxxl)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    dateBadge

                    VStack(alignment: .leading, spacing: 3) {
                        Text(dateTitle)
                            .font(DesignSystem.Typography.title1)
                            .foregroundStyle(DesignSystem.Colors.label)

                        Text(Self.fullDateFormatter.string(from: date))
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)

                        Text(dateContextLine.uppercased())
                            .font(DesignSystem.Typography.caption1.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                            .tracking(0.8)
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.md)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.label)
                        .frame(width: 30, height: 30)
                        .background(DesignSystem.Colors.tertiaryBackground, in: Circle())
                }
                .buttonStyle(InteractiveScaleButtonStyle(scale: 0.92, haptic: true))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(bodyCopy)
                    .font(DesignSystem.Typography.subheadlineEmphasized)
                    .foregroundStyle(DesignSystem.Colors.label)

                if !subscriptions.isEmpty {
                    Text("Review what’s due and jump into any subscription from here.")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.secondaryGroupedBackground)
        )
    }

    private var dateBadge: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(DesignSystem.Colors.primarySubtle)
                    .frame(width: 48, height: 48)

                VStack(spacing: 1) {
                    Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.label)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.weekdayFormatter.string(from: date))
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text(isToday ? "Current billing focus" : "Billing snapshot")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
    }

    private var summaryMetrics: [DayMetric] {
        var metrics: [DayMetric] = [
            DayMetric(
                title: "Total due",
                value: currencyManager.formatAmount(totalCost),
                icon: "banknote.fill",
                tint: DesignSystem.Colors.accent
            ),
            DayMetric(
                title: "Renewals",
                value: "\(subscriptions.count)",
                icon: "arrow.clockwise.circle.fill",
                tint: DesignSystem.Colors.info
            )
        ]

        if activeTrialsCount > 0 {
            metrics.append(
                DayMetric(
                    title: "Trials",
                    value: "\(activeTrialsCount)",
                    icon: "sparkles",
                    tint: DesignSystem.Colors.warning
                )
            )
        }

        if sharedSubscriptionsCount > 0 {
            metrics.append(
                DayMetric(
                    title: "Shared",
                    value: "\(sharedSubscriptionsCount)",
                    icon: "person.2.fill",
                    tint: DesignSystem.Colors.success
                )
            )
        }

        return metrics
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 2), spacing: DesignSystem.Spacing.sm) {
            ForEach(summaryMetrics) { metric in
                DayMetricCard(metric: metric)
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(width: 52, height: 52)

                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Clear day")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text("No subscriptions renew on \(Self.monthDayFormatter.string(from: date)). Long-press a date in the calendar to add one quickly.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.secondaryGroupedBackground)
        )
    }

    private var renewalsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due on this date")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text("Sorted by price so the biggest charges are easiest to spot.")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }

                Spacer()
            }

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(sortedSubscriptions) { subscription in
                    SubscriptionRowView(
                        subscription: subscription,
                        onEdit: { editedSubscription in
                            subscriptionViewModel.updateSubscription(editedSubscription)
                        },
                        onDelete: { subscriptionToDelete in
                            self.subscriptionToDelete = subscriptionToDelete
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
    }

    private var sortedSubscriptions: [Subscription] {
        subscriptions.sorted { lhs, rhs in
            let lhsValue = currencyManager.convertToUserCurrency(lhs.cost, from: lhs.currency)
            let rhsValue = currencyManager.convertToUserCurrency(rhs.cost, from: rhs.currency)
            return lhsValue > rhsValue
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    let onEdit: (Subscription) -> Void
    let onDelete: (Subscription) -> Void

    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingEditSheet = false

    private var convertedCost: Double {
        currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
    }

    private var renewalDescriptor: String {
        switch subscription.billingCycle {
        case .weekly:
            return "Every week"
        case .monthly:
            return "Every month"
        case .quarterly:
            return "Every 3 months"
        case .semiAnnual:
            return "Every 6 months"
        case .annual:
            return "Every year"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                subscriptionIcon

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(subscription.name)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.label)
                            .lineLimit(1)

                        Spacer(minLength: DesignSystem.Spacing.sm)

                        priceBlock
                    }

                    HStack(spacing: 6) {
                        detailChip(
                            title: subscription.category.rawValue,
                            icon: subscription.category.iconName,
                            tint: subscription.category.color
                        )

                        detailChip(
                            title: renewalDescriptor,
                            icon: "calendar",
                            tint: DesignSystem.Colors.info
                        )
                    }

                    if subscription.isTrial || subscription.isSharedSubscription {
                        HStack(spacing: 6) {
                            if subscription.isTrial {
                                detailChip(
                                    title: trialLabel,
                                    icon: "sparkles",
                                    tint: DesignSystem.Colors.warning
                                )
                            }

                            if subscription.isSharedSubscription {
                                detailChip(
                                    title: subscription.splitSummary,
                                    icon: "person.2.fill",
                                    tint: DesignSystem.Colors.success
                                )
                            }
                        }
                    }
                }
            }

            HStack {
                Label("Started \(subscription.startDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock.arrow.circlepath")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .lineLimit(1)

                Spacer()

                menuButton
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.secondaryGroupedBackground)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSubscriptionView(subscription: subscription) { editedSubscription in
                onEdit(editedSubscription)
            }
        }
    }

    private var subscriptionIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                .fill(subscription.category.color.opacity(0.14))
                .frame(width: 44, height: 44)

            Image(systemName: subscription.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(subscription.category.color)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(currencyManager.formatAmount(convertedCost))
                .font(DesignSystem.Typography.headlineEmphasized)
                .foregroundStyle(DesignSystem.Colors.label)
                .monospacedDigit()

            if subscription.currency.code != currencyManager.selectedCurrency.code {
                Text(subscription.formattedCost)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
    }

    private var trialLabel: String {
        if let days = subscription.daysUntilTrialEnds, days >= 0 {
            return days == 0 ? "Trial ends today" : "Trial ends in \(days)d"
        }
        return "Free trial"
    }

    private func detailChip(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title)
                .lineLimit(1)
        }
        .font(DesignSystem.Typography.caption2.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(DesignSystem.Colors.tertiaryBackground, in: Capsule())
    }

    private var menuButton: some View {
        Menu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if #available(iOS 16.1, *) {
                Button {
                    LiveActivityManager.shared.startActivity(for: subscription)
                } label: {
                    Label("Start Live Activity", systemImage: "clock.badge.exclamationmark")
                }
            }

            Button(role: .destructive) {
                onDelete(subscription)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            HStack(spacing: 6) {
                Text("Actions")
                    .font(DesignSystem.Typography.caption2.weight(.semibold))
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(DesignSystem.Colors.tertiaryBackground, in: Capsule())
        }
    }
}

private struct DayMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let tint: Color
}

private struct DayMetricCard: View {
    let metric: DayMetric

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: metric.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(metric.tint)
                .frame(width: 30, height: 30)
                .background(metric.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.value)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)
                    .monospacedDigit()

                Text(metric.title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.secondaryGroupedBackground)
        )
    }
}

#Preview {
    let sampleSubscriptions = [
        Subscription(
            name: "Netflix",
            cost: 13.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming,
            iconName: "tv.fill"
        ),
        Subscription(
            name: "Spotify",
            cost: 9.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Date(),
            category: .music,
            iconName: "music.note",
            isTrial: true,
            trialEndDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
    ]

    DayDetailsView(date: Date(), subscriptions: sampleSubscriptions)
}

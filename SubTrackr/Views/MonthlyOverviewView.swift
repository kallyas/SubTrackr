import SwiftUI

struct MonthlyOverviewView: View {
    @EnvironmentObject private var viewModel: SubscriptionViewModel
    @StateObject private var cloudKitService = CloudKitService.shared
    @ObservedObject private var budgetManager = BudgetManager.shared
    @State private var selectedCategory: SubscriptionCategory?
    @State private var subscriptionToDelete: Subscription?
    @State private var showingDeleteConfirmation = false
    @State private var subscriptionToEdit: Subscription?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if cloudKitService.isLoading && viewModel.subscriptions.isEmpty {
                    OverviewLoadingSkeleton()
                } else {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        if budgetManager.budgetEnabled {
                            budgetProgressCard
                        }
                        monthlyTotalCard
                        spendingChart
                        upcomingRenewals
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                    .screenPadding()
                }
            }
            .background(DesignSystem.Colors.background)
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        DesignSystem.Haptics.light()
                        viewModel.showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignSystem.Colors.accent)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSubscription) {
            EditSubscriptionView(subscription: nil, currentMonthlyTotal: viewModel.monthlyTotal) { subscription in
                viewModel.addSubscription(subscription)
            }
        }
        .sheet(item: $subscriptionToEdit) { subscription in
            EditSubscriptionView(subscription: subscription, currentMonthlyTotal: viewModel.monthlyTotal) { updatedSubscription in
                viewModel.updateSubscription(updatedSubscription)
            }
        }
        .confirmationDialog(
            "Delete Subscription",
            isPresented: $showingDeleteConfirmation,
            presenting: subscriptionToDelete
        ) { subscription in
            Button("Delete \(subscription.name)", role: .destructive) {
                withAnimation(DesignSystem.Animation.springSnappy) {
                    viewModel.deleteSubscription(subscription)
                }
            }
            Button("Cancel", role: .cancel) {
                subscriptionToDelete = nil
            }
        } message: { subscription in
            Text("Are you sure you want to delete \(subscription.name)? This action cannot be undone.")
        }
        .overlay(alignment: .bottom) {
            if viewModel.showingUndoAlert, let deleted = viewModel.recentlyDeletedSubscription {
                UndoBanner(
                    message: "\(deleted.name) deleted",
                    onUndo: {
                        viewModel.undoDelete()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, DesignSystem.Spacing.xxl)
                .screenPadding()
            }
        }
        .animation(DesignSystem.Animation.springSmooth, value: viewModel.showingUndoAlert)
    }

    // MARK: - Actions

    private func refreshData() async {
        // Trigger CloudKit refresh
        CloudKitService.shared.fetchSubscriptions()
        CurrencyExchangeService.shared.forceRefresh()

        // Wait a bit for the refresh to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    // MARK: - Budget Progress Card

    private var budgetProgressCard: some View {
        let budgetConverted = budgetManager.budgetInUserCurrency
        let status = budgetManager.checkBudgetStatus(currentSpending: viewModel.monthlyTotal)
        let progress = budgetConverted > 0 ? min(viewModel.monthlyTotal / budgetConverted, 1.5) : 0
        let remaining = budgetConverted - viewModel.monthlyTotal
        let percentUsed = budgetConverted > 0 ? Int((viewModel.monthlyTotal / budgetConverted) * 100) : 0

        return VStack(spacing: DesignSystem.Spacing.md) {
            // Header row: Status icon + "Budget" on left, status badge on right
            HStack {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(status.color)

                    Text("Budget")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.label)
                }

                Spacer()

                // Status pill
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(status.message)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(status.color))
            }

            // Amount display: "spent / budget" centered, scalable
            HStack(spacing: 4) {
                Text(CurrencyManager.shared.formatAmount(viewModel.monthlyTotal))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(status.color)

                Text("/")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)

                Text(CurrencyManager.shared.formatAmount(budgetConverted))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .frame(maxWidth: .infinity)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(DesignSystem.Colors.tertiaryFill)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(status.color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 10)

            // Bottom row: percentage and remaining, compact
            HStack {
                Text("\(percentUsed)%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(status.color)

                Text("used")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)

                Spacer()

                if remaining >= 0 {
                    Text("\(CurrencyManager.shared.formatAmount(remaining)) left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.success)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                } else {
                    Text("\(CurrencyManager.shared.formatAmount(abs(remaining))) over")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.error)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .strokeBorder(status.color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Monthly Total Card

    private var monthlyTotalCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Large total amount
            VStack(spacing: DesignSystem.Spacing.xs) {
                CounterAnimation(value: viewModel.monthlyTotal)
                    .font(DesignSystem.Typography.displayLarge)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text("per month")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }

            // Active subscriptions count
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.success)

                Text("\(viewModel.subscriptions.filter { $0.isActive && !$0.isArchived }.count) active")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            
            // Annual projection
            Divider()
                .padding(.vertical, DesignSystem.Spacing.sm)
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "calendar.badge.clock")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.accent)

                Text("Annual: ")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                
                Text(CurrencyManager.shared.formatAmount(viewModel.annualTotal))
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)
                
                Text("per year")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .strokeBorder(DesignSystem.Colors.separator.opacity(0.5), lineWidth: 0.5)
        )
        .softShadow()
    }

    // MARK: - Spending Chart

    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("Spending by Category")
                        .font(DesignSystem.Typography.title3)

                    if !viewModel.chartData.isEmpty {
                        Text("\(viewModel.chartData.count) categories")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)

            // Chart
            if viewModel.chartData.isEmpty {
                EmptyStateView(
                    variant: .noCategorySubscriptions,
                    compact: true
                )
                .padding(DesignSystem.Spacing.xxl)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(viewModel.chartData.prefix(6), id: \.category) { item in
                        HorizontalBarChartRow(
                            category: item.category,
                            amount: item.amount,
                            percentage: item.percentage,
                            maxAmount: viewModel.chartData.first?.amount ?? 1,
                            isSelected: selectedCategory == item.category
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DesignSystem.Haptics.selection()
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedCategory = selectedCategory == item.category ? nil : item.category
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .softShadow()
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            Text("Categories")
                .font(DesignSystem.Typography.title3)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)

            // Category rows
            if viewModel.chartData.isEmpty {
                EmptyStateView(
                    variant: .noCategorySubscriptions,
                    compact: true
                )
                .padding(DesignSystem.Spacing.xxl)
            } else {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(viewModel.chartData, id: \.category) { item in
                        CategoryRowView(
                            category: item.category,
                            amount: item.amount,
                            percentage: item.percentage,
                            isSelected: selectedCategory == item.category
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DesignSystem.Haptics.selection()
                            withAnimation(DesignSystem.Animation.springSnappy) {
                                selectedCategory = selectedCategory == item.category ? nil : item.category
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .softShadow()
    }

    // MARK: - Upcoming Renewals

    private var upcomingRenewals: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("Upcoming Renewals")
                    .font(DesignSystem.Typography.title3)

                Spacer()

                Text("Next 7 days")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)

            let upcomingSubscriptions = viewModel.getUpcomingRenewals()

            // Renewals list
            if upcomingSubscriptions.isEmpty {
                EmptyStateView(
                    variant: .noUpcomingRenewals,
                    compact: true
                )
                .padding(DesignSystem.Spacing.xxl)
            } else {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(upcomingSubscriptions) { subscription in
                        UpcomingRenewalRowView(subscription: subscription)
                            .contextMenu {
                                Button {
                                    subscriptionToEdit = subscription
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    subscriptionToDelete = subscription
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .softShadow()
    }
}

// MARK: - Category Row

struct CategoryRowView: View {
    let category: SubscriptionCategory
    let amount: Double
    let percentage: Double
    let isSelected: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.categorySubtle(category.color))
                    .frame(width: 40, height: 40)

                Image(systemName: category.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(category.color)
                    .symbolRenderingMode(.hierarchical)
            }

            // Category info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(category.rawValue)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Percentage bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(DesignSystem.Colors.tertiaryFill)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(category.color)
                                .frame(width: geometry.size.width * (percentage / 100), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 80)

                    Text("\(percentage, specifier: "%.0f")%")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Amount
            Text(CurrencyManager.shared.formatAmount(amount))
                .font(DesignSystem.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.label)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(isSelected ? DesignSystem.Colors.categorySubtle(category.color) : DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .strokeBorder(isSelected ? category.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Upcoming Renewal Row

struct UpcomingRenewalRowView: View {
    let subscription: Subscription

    private var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let renewalDate = calendar.startOfDay(for: subscription.nextBillingDate)
        return calendar.dateComponents([.day], from: today, to: renewalDate).day ?? 0
    }

    private var renewalText: String {
        switch daysUntilRenewal {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(daysUntilRenewal) days"
        }
    }

    private var urgencyColor: Color {
        switch daysUntilRenewal {
        case 0: return DesignSystem.Colors.error
        case 1: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.secondaryLabel
        }
    }

    private var accessibilityLabel: String {
        let currencyManager = CurrencyManager.shared
        let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
        let formattedCost = currencyManager.formatAmount(convertedCost)
        return "\(subscription.name), \(formattedCost), renews \(renewalText.lowercased())"
    }

    private func trialEndText(days: Int) -> String {
        switch days {
        case ..<0: return "Trial expired"
        case 0: return "Trial ends today"
        case 1: return "Trial ends tomorrow"
        default: return "Trial: \(days) days left"
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Subscription icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                    .frame(width: 44, height: 44)

                Image(systemName: subscription.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(subscription.category.color)
                    .symbolRenderingMode(.hierarchical)
            }

            // Subscription info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(subscription.name)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.label)

                    if subscription.isTrial {
                        TrialBadge(subscription: subscription)
                    }
                }

                HStack(spacing: DesignSystem.Spacing.xs) {
                    if subscription.isTrial, let days = subscription.daysUntilTrialEnds {
                        Image(systemName: subscription.isTrialExpiringSoon ? "exclamationmark.triangle.fill" : "gift.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(subscription.isTrialExpiringSoon ? DesignSystem.Colors.error : .orange)

                        Text(trialEndText(days: days))
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(subscription.isTrialExpiringSoon ? DesignSystem.Colors.error : .orange)
                    } else {
                        Image(systemName: daysUntilRenewal == 0 ? "exclamationmark.circle.fill" : "clock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(urgencyColor)

                        Text(renewalText)
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(urgencyColor)
                    }
                }
            }

            Spacer()

            // Amount
            let currencyManager = CurrencyManager.shared
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)

            Text(currencyManager.formatAmount(convertedCost))
                .font(DesignSystem.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.label)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Long press for more options")
    }
}

// MARK: - Custom Pie Chart

struct CustomPieChart: View {
    let data: [(category: SubscriptionCategory, amount: Double, percentage: Double)]
    let selectedCategory: SubscriptionCategory?

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: 70,
                    outerRadius: 100
                )
                .fill(item.category.color)
                .opacity(opacityFor(category: item.category))
                .scaleEffect(selectedCategory == item.category ? 1.05 : 1.0)
                .shadow(
                    color: selectedCategory == item.category ? item.category.color.opacity(0.3) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }

            // Inner circle for donut effect
            Circle()
                .fill(DesignSystem.Colors.secondaryBackground)
                .frame(width: 140, height: 140)
        }
        .animation(DesignSystem.Animation.springSmooth, value: selectedCategory)
    }

    private func opacityFor(category: SubscriptionCategory) -> Double {
        if selectedCategory == nil {
            return 1.0
        }
        return selectedCategory == category ? 1.0 : 0.3
    }

    private func startAngle(for index: Int) -> Angle {
        let totalPercentage = data.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle(degrees: totalPercentage * 3.6 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let totalPercentage = data.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return Angle(degrees: totalPercentage * 3.6 - 90)
    }
}

// MARK: - Pie Slice Shape

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()

        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Horizontal Bar Chart Row

struct HorizontalBarChartRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let percentage: Double
    let maxAmount: Double
    let isSelected: Bool
    
    private var barWidth: CGFloat {
        guard maxAmount > 0 else { return 0 }
        return CGFloat(amount / maxAmount)
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.categorySubtle(category.color))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(category.color)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 36)
            
            // Bar and amount
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                // Category name and amount
                HStack {
                    Text(category.rawValue)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(DesignSystem.Colors.label)
                    
                    Spacer()
                    
                    Text(CurrencyManager.shared.formatAmount(amount))
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.label)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(DesignSystem.Colors.tertiaryFill)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(category.color)
                            .frame(width: geometry.size.width * barWidth, height: 6)
                    }
                }
                .frame(height: 6)
                
                // Percentage
                Text("\(percentage, specifier: "%.1f")%")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(isSelected ? DesignSystem.Colors.categorySubtle(category.color) : DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .strokeBorder(isSelected ? category.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    MonthlyOverviewView()
        .environmentObject(SubscriptionViewModel())
}

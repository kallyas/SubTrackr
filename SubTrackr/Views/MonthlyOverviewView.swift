import SwiftUI

struct MonthlyOverviewView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedCategory: SubscriptionCategory?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    monthlyTotalCard
                    spendingChart
                    categoryBreakdown
                    upcomingRenewals
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
                .screenPadding()
            }
            .background(DesignSystem.Colors.background)
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
            EditSubscriptionView(subscription: nil) { subscription in
                viewModel.addSubscription(subscription)
            }
        }
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

                Text("\(viewModel.subscriptions.filter(\.isActive).count) active")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)

                if viewModel.subscriptions.filter({ !$0.isActive }).count > 0 {
                    Circle()
                        .fill(DesignSystem.Colors.quaternaryLabel)
                        .frame(width: 3, height: 3)

                    Text("\(viewModel.subscriptions.filter({ !$0.isActive }).count) inactive")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }
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
                ZStack {
                    // Pie chart
                    CustomPieChart(
                        data: viewModel.chartData,
                        selectedCategory: selectedCategory
                    )
                    .frame(height: 220)
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                    // Center text showing selected category
                    if let selected = selectedCategory,
                       let item = viewModel.chartData.first(where: { $0.category == selected }) {
                        VStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(CurrencyManager.shared.formatAmount(item.amount))
                                .font(DesignSystem.Typography.title3)
                                .foregroundStyle(selected.color)

                            Text("\(item.percentage, specifier: "%.0f")%")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                }
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
                Text(subscription.name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: daysUntilRenewal == 0 ? "exclamationmark.circle.fill" : "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(urgencyColor)

                    Text(renewalText)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(urgencyColor)
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

#Preview {
    MonthlyOverviewView()
}

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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var totalCost: Double {
        return subscriptions.reduce(0) { total, subscription in
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            return total + convertedCost
        }
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
            return shortDateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                dragIndicator
                
                if subscriptions.isEmpty {
                    emptyStateView
                } else {
                    subscriptionsList
                }
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
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
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(DesignSystem.Colors.tertiaryLabel)
            .frame(width: 36, height: 5)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.md)
    }
    
    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Close")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(DesignSystem.Colors.accent)
                }
                
                Spacer()
                
                if !subscriptions.isEmpty {
                    Text(currencyManager.formatAmount(totalCost))
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Text(dateTitle)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.label)
                
                Text(dayFormatter.string(from: date))
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.md)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Subscriptions")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)
                
                Text("You don't have any subscriptions due on this day.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .overlay(headerView, alignment: .top)
    }
    
    private var subscriptionsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(subscriptions) { subscription in
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
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xxxl)
            }
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    let onEdit: (Subscription) -> Void
    let onDelete: (Subscription) -> Void
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            subscriptionIcon
            subscriptionInfo
            Spacer()
            costInfo
            menuButton
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .stroke(subscription.category.color.opacity(0.2), lineWidth: 1)
        )
        .softShadow()
        .sheet(isPresented: $showingEditSheet) {
            EditSubscriptionView(subscription: subscription) { editedSubscription in
                onEdit(editedSubscription)
            }
        }
    }
    
    private var subscriptionIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                .frame(width: 48, height: 48)
            
            Image(systemName: subscription.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(subscription.category.color)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    private var subscriptionInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subscription.name)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.label)
                .lineLimit(1)
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(subscription.category.rawValue)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                
                Circle()
                    .fill(DesignSystem.Colors.quaternaryLabel)
                    .frame(width: 3, height: 3)
                
                Text(subscription.billingCycle.rawValue)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            
            if subscription.isTrial {
                HStack(spacing: 2) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("Trial")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.orange)
                )
            }
        }
    }
    
    private var costInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            
            Text(currencyManager.formatAmount(convertedCost))
                .font(DesignSystem.Typography.callout)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.label)
                .monospacedDigit()
            
            if subscription.currency.code != currencyManager.selectedCurrency.code {
                Text(subscription.formattedCost)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            }
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete(subscription)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .frame(width: 32, height: 32)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipShape(Circle())
        }
    }
}

#Preview {
    let sampleSubscriptions = [
        Subscription(
            name: "Netflix",
            cost: 13.99,
            currency: .USD, billingCycle: .monthly,
            startDate: Date(),
            category: .streaming,
            iconName: "tv.fill"
        ),
        Subscription(
            name: "Spotify",
            cost: 9.99,
            currency: .USD, billingCycle: .monthly,
            startDate: Date(),
            category: .music,
            iconName: "music.note"
        )
    ]
    
    DayDetailsView(date: Date(), subscriptions: sampleSubscriptions)
}

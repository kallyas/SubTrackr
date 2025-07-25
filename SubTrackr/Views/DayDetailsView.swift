import SwiftUI

struct DayDetailsView: View {
    let date: Date
    let subscriptions: [Subscription]
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingDeleteAlert = false
    @State private var subscriptionToDelete: Subscription?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var totalCost: Double {
        return subscriptions.reduce(0) { total, subscription in
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            return total + convertedCost
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                if subscriptions.isEmpty {
                    emptyStateView
                } else {
                    subscriptionsList
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
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
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(Color.accentColor)
                
                Spacer()
                
                Text("Day Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("") // Placeholder for balance
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            VStack(spacing: 4) {
                Text(dateFormatter.string(from: date))
                    .font(.title3)
                    .fontWeight(.medium)
                
                if !subscriptions.isEmpty {
                    Text("Total: \(currencyManager.formatAmount(totalCost))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Material.regularMaterial)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Subscriptions")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("You don't have any subscriptions due on this day.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var subscriptionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
            .padding()
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
        HStack(spacing: 12) {
            subscriptionIcon
            subscriptionInfo
            Spacer()
            costInfo
            menuButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(subscription.category.color.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSubscriptionView(subscription: subscription) { editedSubscription in
                onEdit(editedSubscription)
            }
        }
    }
    
    private var subscriptionIcon: some View {
        ZStack {
            Circle()
                .fill(subscription.category.color.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Image(systemName: subscription.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(subscription.category.color)
        }
    }
    
    private var subscriptionInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subscription.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subscription.category.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Started \(subscription.startDate, style: .date)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var costInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            
            Text(currencyManager.formatAmount(convertedCost))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if subscription.currency.code != currencyManager.selectedCurrency.code {
                Text(subscription.formattedCost)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(subscription.billingCycle.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Material.ultraThinMaterial))
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

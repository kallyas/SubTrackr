import SwiftUI

struct ShareSubscriptionView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @State private var selectedSubscription: Subscription?
    @State private var showingAddMember = false
    @State private var showingSubscriptionPicker = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.subscriptions.isEmpty {
                    Section {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                            
                            Text("No Subscriptions Yet")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.label)
                            
                            Text("Add subscriptions first, then come back to share them with family or friends")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xxl)
                    }
                } else {
                    // Section to add sharing to a subscription
                    Section {
                        Button {
                            showingSubscriptionPicker = true
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(DesignSystem.Colors.accent)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add Shared Subscription")
                                        .font(DesignSystem.Typography.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(DesignSystem.Colors.label)
                                    
                                    Text("Select a subscription to share")
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Already shared subscriptions
                    let sharedSubscriptions = viewModel.subscriptions.filter { !$0.sharedWith.isEmpty }
                    if !sharedSubscriptions.isEmpty {
                        Section("Shared Subscriptions") {
                            ForEach(sharedSubscriptions) { subscription in
                                SharedSubscriptionRow(
                                    subscription: subscription,
                                    onAddMember: {
                                        selectedSubscription = subscription
                                        showingAddMember = true
                                    },
                                    onRemoveMember: { member in
                                        removeMember(member, from: subscription)
                                    }
                                )
                            }
                        }
                    }
                }
                
                Section("How It Works") {
                    FeatureExplanationRow(
                        icon: "person.2.fill",
                        title: "Track Shared Costs",
                        description: "Add family members or friends to track who's paying for what"
                    )
                    
                    FeatureExplanationRow(
                        icon: "dollarsign.circle.fill",
                        title: "Split Expenses",
                        description: "See your share of the cost when splitting subscriptions"
                    )
                    
                    FeatureExplanationRow(
                        icon: "bell.fill",
                        title: "Renewal Reminders",
                        description: "Get notified about upcoming renewals for shared subs"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Share & Split")
            .sheet(isPresented: $showingSubscriptionPicker) {
                SubscriptionPickerSheet(
                    subscriptions: viewModel.subscriptions.filter { $0.sharedWith.isEmpty },
                    onSelect: { subscription in
                        selectedSubscription = subscription
                        showingSubscriptionPicker = false
                        showingAddMember = true
                    }
                )
            }
            .sheet(isPresented: $showingAddMember) {
                if let subscription = selectedSubscription {
                    AddSharedMemberSheet(
                        subscription: subscription,
                        onAdd: { member in
                            addMember(member, to: subscription)
                        }
                    )
                }
            }
        }
    }
    
    private func addMember(_ member: SharedMember, to subscription: Subscription) {
        if let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            viewModel.subscriptions[index].sharedWith.append(member)
            viewModel.updateSubscription(viewModel.subscriptions[index])
        }
    }
    
    private func removeMember(_ member: SharedMember, from subscription: Subscription) {
        if let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            viewModel.subscriptions[index].sharedWith.removeAll { $0.id == member.id }
            viewModel.updateSubscription(viewModel.subscriptions[index])
        }
    }
}

struct SharedSubscriptionRow: View {
    let subscription: Subscription
    let onAddMember: () -> Void
    let onRemoveMember: (SharedMember) -> Void
    
    var body: some View {
        DisclosureGroup {
            ForEach(subscription.sharedWith) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: member.shareType.iconName)
                                .foregroundStyle(DesignSystem.Colors.accent)
                            Text(member.name)
                                .font(DesignSystem.Typography.callout)
                        }
                        
                        if member.isPayer {
                            Text("Payer")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        onRemoveMember(member)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.error)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                onAddMember()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text("Add Member")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        } label: {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(subscription.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: subscription.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(subscription.category.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                    
                    Text("\(subscription.sharedWith.count) member\(subscription.sharedWith.count == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }
                
                Spacer()
                
                Text(subscription.formattedCost)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.label)
            }
        }
    }
}

struct AddSharedMemberSheet: View {
    let subscription: Subscription
    let onAdd: (SharedMember) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var shareType: ShareType = .family
    @State private var isPayer = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Info") {
                    TextField("Name", text: $name)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Relationship") {
                    Picker("Share Type", selection: $shareType) {
                        ForEach(ShareType.allCases) { type in
                            Label(type.rawValue, systemImage: shareTypeIcon(type))
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Is Payer", isOn: $isPayer)
                }
                
                Section {
                    HStack {
                        Text("Monthly Cost")
                        Spacer()
                        Text(subscription.formattedCost)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }
                    
                    HStack {
                        Text("Your Share")
                        Spacer()
                        Text(subscription.currency.formatAmount(subscription.cost / Double(subscription.sharedWith.count + 1)))
                            .foregroundStyle(DesignSystem.Colors.success)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Cost Breakdown")
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let member = SharedMember(
                            name: name,
                            email: email,
                            shareType: shareType,
                            isPayer: isPayer
                        )
                        onAdd(member)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func shareTypeIcon(_ type: ShareType) -> String {
        switch type {
        case .family: return "household"
        case .friend: return "person.2.fill"
        case .partner: return "heart.fill"
        case .colleague: return "building.2.fill"
        case .other: return "person.fill"
        }
    }
}

struct FeatureExplanationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SubscriptionPickerSheet: View {
    let subscriptions: [Subscription]
    let onSelect: (Subscription) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredSubscriptions: [Subscription] {
        if searchText.isEmpty {
            return subscriptions
        }
        return subscriptions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredSubscriptions.isEmpty {
                    Section {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(DesignSystem.Colors.success)
                            
                            Text("All subscriptions are shared!")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xl)
                    }
                } else {
                    ForEach(filteredSubscriptions) { subscription in
                        Button {
                            onSelect(subscription)
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: subscription.iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(subscription.category.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(subscription.name)
                                        .font(DesignSystem.Typography.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(DesignSystem.Colors.label)
                                    
                                    Text(subscription.formattedCost)
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search subscriptions...")
            .navigationTitle("Select Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ShareSubscriptionView(viewModel: SubscriptionViewModel())
}

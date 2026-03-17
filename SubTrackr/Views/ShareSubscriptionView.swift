import SwiftUI

struct ShareSubscriptionView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingSubscriptionPicker = false
    @State private var editorContext: SharedMemberEditorContext?

    private var sharedSubscriptions: [Subscription] {
        viewModel.subscriptions
            .filter(\.isSharedSubscription)
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var unsharedSubscriptions: [Subscription] {
        viewModel.subscriptions
            .filter { !$0.isSharedSubscription }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var yourSharedMonthlyTotal: Double {
        sharedSubscriptions.reduce(0) { total, subscription in
            let convertedShare = currencyManager.convertToUserCurrency(subscription.yourMonthlyShare, from: subscription.currency)
            return total + convertedShare
        }
    }

    private var activePayerCount: Int {
        sharedSubscriptions.reduce(0) { count, subscription in
            count + (subscription.activeSharingBillingMode == .youPay ? 1 : 0)
        }
    }

    private var sharedPeopleCount: Int {
        sharedSubscriptions.reduce(0) { total, subscription in
            total + subscription.otherParticipantsCount
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    SharedOverviewCard(
                        sharedSubscriptionCount: sharedSubscriptions.count,
                        sharedPeopleCount: sharedPeopleCount,
                        yourSharedMonthlyTotal: currencyManager.formatAmount(yourSharedMonthlyTotal),
                        billedByYouCount: activePayerCount
                    )

                    LocalOnlyNoteCard()

                    if viewModel.subscriptions.isEmpty {
                        EmptyShareStateCard()
                    } else {
                        if !unsharedSubscriptions.isEmpty {
                            ShareSetupSection(
                                unsharedCount: unsharedSubscriptions.count,
                                onSetUp: {
                                    showingSubscriptionPicker = true
                                }
                            )
                        }

                        if sharedSubscriptions.isEmpty {
                            EmptyConfiguredShareCard()
                        } else {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Shared subscriptions")
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundStyle(DesignSystem.Colors.label)

                                ForEach(sharedSubscriptions) { subscription in
                                    SharedSubscriptionCard(
                                        subscription: subscription,
                                        userCurrencyCode: currencyManager.selectedCurrency.code,
                                        formattedYourMonthlyShare: formatInUserCurrency(subscription.yourMonthlyShare, from: subscription.currency),
                                        onAddMember: {
                                            editorContext = SharedMemberEditorContext(subscription: subscription)
                                        },
                                        onEditMember: { member in
                                            editorContext = SharedMemberEditorContext(subscription: subscription, member: member)
                                        },
                                        onRemoveMember: { member in
                                            removeMember(member, from: subscription)
                                        },
                                        onBillingModeChange: { billingMode in
                                            updateBillingMode(billingMode, for: subscription)
                                        },
                                        onSetPayer: { member in
                                            setPayer(member, for: subscription)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.groupedBackground.ignoresSafeArea())
            .navigationTitle("People & Split")
            .sheet(isPresented: $showingSubscriptionPicker) {
                SubscriptionPickerSheet(
                    subscriptions: unsharedSubscriptions,
                    onSelect: { subscription in
                        showingSubscriptionPicker = false
                        editorContext = SharedMemberEditorContext(subscription: subscription)
                    }
                )
            }
            .sheet(item: $editorContext) { context in
                SharedMemberEditorSheet(
                    subscription: context.subscription,
                    existingMember: context.member,
                    initialBillingMode: context.subscription.activeSharingBillingMode,
                    onSave: { member, billingMode in
                        saveMember(member, for: context.subscription, replacing: context.member, billingMode: billingMode)
                    }
                )
            }
        }
    }

    private func formatInUserCurrency(_ amount: Double, from currency: Currency) -> String {
        let convertedAmount = currencyManager.convertToUserCurrency(amount, from: currency)
        return currencyManager.formatAmount(convertedAmount)
    }

    private func updateBillingMode(_ billingMode: SharingBillingMode, for subscription: Subscription) {
        guard let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        var updatedSubscription = viewModel.subscriptions[index]
        updatedSubscription.sharingBillingMode = billingMode

        switch billingMode {
        case .splitEqually, .youPay:
            updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { member in
                var updatedMember = member
                updatedMember.isPayer = false
                return updatedMember
            }
        case .otherPays:
            if updatedSubscription.payerMember == nil, !updatedSubscription.sharedWith.isEmpty {
                updatedSubscription.sharedWith = updatedSubscription.sharedWith.enumerated().map { offset, member in
                    var updatedMember = member
                    updatedMember.isPayer = offset == 0
                    return updatedMember
                }
            }
        }

        viewModel.updateSubscription(updatedSubscription)
    }

    private func setPayer(_ member: SharedMember, for subscription: Subscription) {
        guard let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        var updatedSubscription = viewModel.subscriptions[index]
        updatedSubscription.sharingBillingMode = .otherPays
        updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { currentMember in
            var updatedMember = currentMember
            updatedMember.isPayer = currentMember.id == member.id
            return updatedMember
        }

        viewModel.updateSubscription(updatedSubscription)
    }

    private func saveMember(_ member: SharedMember, for subscription: Subscription, replacing existingMember: SharedMember?, billingMode: SharingBillingMode) {
        guard let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        var updatedSubscription = viewModel.subscriptions[index]

        if let existingMember,
           let memberIndex = updatedSubscription.sharedWith.firstIndex(where: { $0.id == existingMember.id }) {
            updatedSubscription.sharedWith[memberIndex] = member
        } else {
            updatedSubscription.sharedWith.append(member)
        }

        updatedSubscription.sharingBillingMode = billingMode

        if billingMode == .otherPays {
            updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { currentMember in
                var updatedMember = currentMember
                updatedMember.isPayer = currentMember.id == member.id ? member.isPayer : (member.isPayer ? false : currentMember.isPayer)
                return updatedMember
            }

            if updatedSubscription.payerMember == nil, let firstMember = updatedSubscription.sharedWith.first {
                updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { currentMember in
                    var updatedMember = currentMember
                    updatedMember.isPayer = currentMember.id == firstMember.id
                    return updatedMember
                }
            }
        } else {
            updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { currentMember in
                var updatedMember = currentMember
                updatedMember.isPayer = false
                return updatedMember
            }
        }

        viewModel.updateSubscription(updatedSubscription)
    }

    private func removeMember(_ member: SharedMember, from subscription: Subscription) {
        guard let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        var updatedSubscription = viewModel.subscriptions[index]
        updatedSubscription.sharedWith.removeAll { $0.id == member.id }

        if updatedSubscription.sharedWith.isEmpty {
            updatedSubscription.sharingBillingMode = .splitEqually
        } else if updatedSubscription.activeSharingBillingMode == .otherPays,
                  updatedSubscription.payerMember == nil,
                  let firstMember = updatedSubscription.sharedWith.first {
            updatedSubscription.sharedWith = updatedSubscription.sharedWith.map { currentMember in
                var updatedMember = currentMember
                updatedMember.isPayer = currentMember.id == firstMember.id
                return updatedMember
            }
        }

        viewModel.updateSubscription(updatedSubscription)
    }
}

private struct SharedMemberEditorContext: Identifiable {
    let subscription: Subscription
    let member: SharedMember?

    init(subscription: Subscription, member: SharedMember? = nil) {
        self.subscription = subscription
        self.member = member
    }

    var id: String {
        "\(subscription.id)-\(member?.id ?? "new")"
    }
}

private struct SharedOverviewCard: View {
    let sharedSubscriptionCount: Int
    let sharedPeopleCount: Int
    let yourSharedMonthlyTotal: String
    let billedByYouCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Shared subscription planning")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(.white)

                Text("See who is on each subscription, who pays the bill, and what your share looks like month to month.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                SummaryMetric(
                    title: "Your monthly share",
                    value: yourSharedMonthlyTotal,
                    icon: "wallet.pass.fill"
                )

                SummaryMetric(
                    title: "Shared plans",
                    value: "\(sharedSubscriptionCount)",
                    icon: "square.stack.3d.up.fill"
                )
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                SummaryMetric(
                    title: "People tracked",
                    value: "\(sharedPeopleCount)",
                    icon: "person.2.fill"
                )

                SummaryMetric(
                    title: "Bills you cover",
                    value: "\(billedByYouCount)",
                    icon: "creditcard.fill"
                )
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.24, blue: 0.47),
                    Color(red: 0.08, green: 0.45, blue: 0.54)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.headlineEmphasized)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
    }
}

private struct LocalOnlyNoteCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.info)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("This is local planning, not live collaboration")
                    .font(DesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text("Use this screen to track participants and split logic on your SubTrackr account. It does not invite other people into the app yet.")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }
}

private struct ShareSetupSection: View {
    let unsharedCount: Int
    let onSetUp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Set up a split")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.label)

            Button(action: onSetUp) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .fill(DesignSystem.Colors.accent.opacity(0.14))
                            .frame(width: 48, height: 48)

                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose a subscription")
                            .font(DesignSystem.Typography.calloutEmphasized)
                            .foregroundStyle(DesignSystem.Colors.label)

                        Text("\(unsharedCount) subscription\(unsharedCount == 1 ? "" : "s") ready for people and split tracking")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct EmptyShareStateCard: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No subscriptions yet")
                    .font(DesignSystem.Typography.headlineEmphasized)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text("Add subscriptions first, then come back here to track who shares them and how the bill is handled.")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxl)
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }
}

private struct EmptyConfiguredShareCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("No shared subscriptions configured")
                .font(DesignSystem.Typography.headlineEmphasized)
                .foregroundStyle(DesignSystem.Colors.label)

            Text("Pick a subscription above to start tracking the people involved and whether the bill is split, covered by you, or paid by someone else.")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }
}

private struct SharedSubscriptionCard: View {
    let subscription: Subscription
    let userCurrencyCode: String
    let formattedYourMonthlyShare: String
    let onAddMember: () -> Void
    let onEditMember: (SharedMember) -> Void
    let onRemoveMember: (SharedMember) -> Void
    let onBillingModeChange: (SharingBillingMode) -> Void
    let onSetPayer: (SharedMember) -> Void

    @State private var isExpanded = true

    private var billingAmountSummary: String {
        "\(subscription.formattedCost) per \(subscription.billingCycle.rawValue.lowercased())"
    }

    private var yourCycleShare: String {
        subscription.currency.formatAmount(subscription.yourShareCost)
    }

    private var participantSummary: String {
        if subscription.otherParticipantsCount == 1 {
            return "You + 1 other"
        }

        return "You + \(subscription.otherParticipantsCount) others"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                        .frame(width: 52, height: 52)

                    Image(systemName: subscription.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(subscription.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(DesignSystem.Typography.headlineEmphasized)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text(billingAmountSummary)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        InsightChip(text: subscription.activeSharingBillingMode.shortLabel, icon: subscription.activeSharingBillingMode.iconName)
                        InsightChip(text: participantSummary, icon: "person.2.fill")
                        InsightChip(text: subscription.splitSummary, icon: "creditcard.circle.fill")
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.sm)

                Button {
                    withAnimation(DesignSystem.Animation.standard) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                CostSnapshotCard(
                    title: "Total bill",
                    value: subscription.formattedCost,
                    subtitle: subscription.billingCycle.rawValue
                )

                CostSnapshotCard(
                    title: "Your share",
                    value: yourCycleShare,
                    subtitle: "\(formattedYourMonthlyShare)/mo"
                )
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Billing setup")
                            .font(DesignSystem.Typography.calloutEmphasized)
                            .foregroundStyle(DesignSystem.Colors.label)

                        Picker("Billing setup", selection: Binding(
                            get: { subscription.activeSharingBillingMode },
                            set: onBillingModeChange
                        )) {
                            ForEach(availableBillingModes) { mode in
                                Label(mode.rawValue, systemImage: mode.iconName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if subscription.activeSharingBillingMode == .otherPays, !subscription.sharedWith.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Who pays the bill")
                                .font(DesignSystem.Typography.calloutEmphasized)
                                .foregroundStyle(DesignSystem.Colors.label)

                            ForEach(subscription.sharedWith) { member in
                                Button {
                                    onSetPayer(member)
                                } label: {
                                    HStack {
                                        Text(member.name)
                                            .font(DesignSystem.Typography.callout)
                                            .foregroundStyle(DesignSystem.Colors.label)

                                        Spacer()

                                        if member.isPayer {
                                            Label("Paying", systemImage: "checkmark.circle.fill")
                                                .font(DesignSystem.Typography.caption1)
                                                .foregroundStyle(DesignSystem.Colors.success)
                                        } else {
                                            Text("Set as payer")
                                                .font(DesignSystem.Typography.caption1)
                                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                        }
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .background(DesignSystem.Colors.tertiaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("People")
                                .font(DesignSystem.Typography.calloutEmphasized)
                                .foregroundStyle(DesignSystem.Colors.label)

                            Spacer()

                            Button(action: onAddMember) {
                                Label("Add person", systemImage: "plus.circle.fill")
                                    .font(DesignSystem.Typography.callout)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(subscription.sharedWith) { member in
                            SharedMemberRow(
                                member: member,
                                subscription: subscription,
                                onEdit: { onEditMember(member) },
                                onRemove: { onRemoveMember(member) }
                            )
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous))
    }

    private var availableBillingModes: [SharingBillingMode] {
        if subscription.sharedWith.isEmpty {
            return [.splitEqually, .youPay]
        }

        return SharingBillingMode.allCases
    }
}

private struct CostSnapshotCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.label)
                .monospacedDigit()

            Text(subtitle)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

private struct InsightChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(DesignSystem.Typography.caption2)
            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            .lineLimit(1)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 6)
            .background(DesignSystem.Colors.tertiaryBackground)
            .clipShape(Capsule())
    }
}

private struct SharedMemberRow: View {
    let member: SharedMember
    let subscription: Subscription
    let onEdit: () -> Void
    let onRemove: () -> Void

    private var detailText: String {
        switch subscription.activeSharingBillingMode {
        case .splitEqually:
            let splitAmount = subscription.currency.formatAmount(subscription.cost / Double(max(subscription.participantCount, 1)))
            return "\(member.shareType.rawValue) • \(splitAmount) share"
        case .youPay:
            return "\(member.shareType.rawValue) • Covered by you"
        case .otherPays:
            if member.isPayer {
                return "\(member.shareType.rawValue) • Pays full bill"
            }
            return "\(member.shareType.rawValue) • Participant"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: member.shareType.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(member.name)
                        .font(DesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(DesignSystem.Colors.label)

                    if member.isPayer {
                        Text("Payer")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(DesignSystem.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(DesignSystem.Colors.successSubtle)
                            .clipShape(Capsule())
                    }
                }

                Text(detailText)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)

                if !member.email.isEmpty {
                    Text(member.email)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }
            }

            Spacer()

            VStack(spacing: DesignSystem.Spacing.xs) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

struct SharedMemberEditorSheet: View {
    let subscription: Subscription
    let existingMember: SharedMember?
    let initialBillingMode: SharingBillingMode
    let onSave: (SharedMember, SharingBillingMode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var shareType: ShareType
    @State private var isPayer: Bool
    @State private var billingMode: SharingBillingMode

    init(
        subscription: Subscription,
        existingMember: SharedMember? = nil,
        initialBillingMode: SharingBillingMode,
        onSave: @escaping (SharedMember, SharingBillingMode) -> Void
    ) {
        self.subscription = subscription
        self.existingMember = existingMember
        self.initialBillingMode = initialBillingMode
        self.onSave = onSave
        _name = State(initialValue: existingMember?.name ?? "")
        _email = State(initialValue: existingMember?.email ?? "")
        _shareType = State(initialValue: existingMember?.shareType ?? .family)
        _isPayer = State(initialValue: (existingMember?.isPayer) ?? (initialBillingMode == .otherPays))
        _billingMode = State(initialValue: initialBillingMode)
    }

    private var participantCountAfterSave: Int {
        if existingMember == nil {
            return subscription.participantCount + 1
        }

        return subscription.participantCount
    }

    private var equalSharePreview: String {
        let splitAmount = subscription.cost / Double(max(participantCountAfterSave, 1))
        return subscription.currency.formatAmount(splitAmount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Billing setup") {
                    Picker("How is the bill handled?", selection: $billingMode) {
                        ForEach(availableBillingModes) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if billingMode == .otherPays {
                        Toggle("This person pays the bill", isOn: $isPayer)
                    }
                }

                Section("Person") {
                    TextField("Name", text: $name)

                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Relationship", selection: $shareType) {
                        ForEach(ShareType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }

                Section("Preview") {
                    LabeledContent("Subscription") {
                        Text("\(subscription.formattedCost) per \(subscription.billingCycle.rawValue.lowercased())")
                    }

                    LabeledContent("Billing mode") {
                        Text(billingMode.shortLabel)
                    }

                    if billingMode == .splitEqually {
                        LabeledContent("Each person pays") {
                            Text(equalSharePreview)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    } else if billingMode == .youPay {
                        LabeledContent("This person") {
                            Text("Included, but not paying")
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                    } else {
                        LabeledContent("This person") {
                            Text(isPayer ? "Pays the full bill" : "Participant only")
                                .foregroundStyle(isPayer ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryLabel)
                        }
                    }
                }
            }
            .navigationTitle(existingMember == nil ? "Add Person" : "Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(existingMember == nil ? "Add" : "Save") {
                        let member = SharedMember(
                            id: existingMember?.id ?? UUID().uuidString,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                            shareType: shareType,
                            isPayer: billingMode == .otherPays ? isPayer : false,
                            addedDate: existingMember?.addedDate ?? Date()
                        )

                        onSave(member, billingMode)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: billingMode) { _, newValue in
                if newValue != .otherPays {
                    isPayer = false
                }
            }
        }
    }

    private var availableBillingModes: [SharingBillingMode] {
        if subscription.sharedWith.isEmpty && existingMember == nil {
            return [.splitEqually, .youPay, .otherPays]
        }

        return SharingBillingMode.allCases
    }
}

struct SubscriptionPickerSheet: View {
    let subscriptions: [Subscription]
    let onSelect: (Subscription) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredSubscriptions: [Subscription] {
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

                            Text(subscriptions.isEmpty ? "Everything is already configured" : "No matching subscriptions")
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
                                        .frame(width: 42, height: 42)

                                    Image(systemName: subscription.iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(subscription.category.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(subscription.name)
                                        .font(DesignSystem.Typography.calloutEmphasized)
                                        .foregroundStyle(DesignSystem.Colors.label)

                                    Text("\(subscription.formattedCost) per \(subscription.billingCycle.rawValue.lowercased())")
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
            .searchable(text: $searchText, prompt: "Search subscriptions")
            .navigationTitle("Choose a Subscription")
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

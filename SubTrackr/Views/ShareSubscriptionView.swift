import SwiftUI

struct ShareSubscriptionView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingSubscriptionPicker = false
    @State private var detailSubscriptionID: String?

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

    private var selectedSubscription: Subscription? {
        guard let detailSubscriptionID else { return nil }
        return viewModel.subscriptions.first(where: { $0.id == detailSubscriptionID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    SplitSummaryCard(
                        monthlyShare: currencyManager.formatAmount(yourSharedMonthlyTotal),
                        sharedPlanCount: sharedSubscriptions.count,
                        sharedPeopleCount: sharedPeopleCount,
                        billedByYouCount: activePayerCount
                    )

                    planningNote

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
                            configuredSplitsSection
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.groupedBackground.ignoresSafeArea())
            .navigationTitle("Split Costs")
            .sheet(isPresented: $showingSubscriptionPicker) {
                SubscriptionPickerSheet(
                    subscriptions: unsharedSubscriptions,
                    onSelect: { subscription in
                        showingSubscriptionPicker = false
                        detailSubscriptionID = subscription.id
                    }
                )
            }
            .sheet(item: detailBinding) { subscription in
                SplitSubscriptionDetailSheet(
                    subscription: subscription,
                    formattedYourMonthlyShare: formatInUserCurrency(subscription.yourMonthlyShare, from: subscription.currency),
                    onBillingModeChange: { billingMode in
                        updateBillingMode(billingMode, for: subscription)
                    },
                    onSaveMember: { member, existingMember in
                        saveMember(member, for: subscription, replacing: existingMember)
                    },
                    onRemoveMember: { member in
                        removeMember(member, from: subscription)
                    },
                    onSetPayer: { member in
                        setPayer(member, for: subscription)
                    }
                )
            }
        }
    }

    private var detailBinding: Binding<Subscription?> {
        Binding(
            get: { selectedSubscription },
            set: { newValue in
                detailSubscriptionID = newValue?.id
            }
        )
    }

    private var planningNote: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Local split planning")
                .font(DesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(DesignSystem.Colors.label)

            Text("Track who is included, how the bill is handled, and what your share looks like. This does not invite or sync with other people yet.")
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var configuredSplitsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Configured Splits")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text("\(sharedSubscriptions.count) subscription\(sharedSubscriptions.count == 1 ? "" : "s") with tracked participants")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(sharedSubscriptions) { subscription in
                    SplitSubscriptionRow(
                        subscription: subscription,
                        formattedYourMonthlyShare: formatInUserCurrency(subscription.yourMonthlyShare, from: subscription.currency),
                        onTap: {
                            detailSubscriptionID = subscription.id
                        }
                    )
                }
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

    private func saveMember(_ member: SharedMember, for subscription: Subscription, replacing existingMember: SharedMember?) {
        guard let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }

        var updatedSubscription = viewModel.subscriptions[index]

        if let existingMember,
           let memberIndex = updatedSubscription.sharedWith.firstIndex(where: { $0.id == existingMember.id }) {
            let preservedPayerState = updatedSubscription.sharedWith[memberIndex].isPayer
            var updatedMember = member
            updatedMember.isPayer = preservedPayerState
            updatedSubscription.sharedWith[memberIndex] = updatedMember
        } else {
            updatedSubscription.sharedWith.append(member)
        }

        if updatedSubscription.activeSharingBillingMode == .otherPays,
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
    let member: SharedMember?

    init(member: SharedMember? = nil) {
        self.member = member
    }

    var id: String {
        member?.id ?? "new"
    }
}

private struct SplitSummaryCard: View {
    let monthlyShare: String
    let sharedPlanCount: Int
    let sharedPeopleCount: Int
    let billedByYouCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Your split snapshot")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text(monthlyShare)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.label)
                    .monospacedDigit()

                Text("Your current monthly cost across shared subscriptions")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                SplitMetricTile(title: "Plans", value: "\(sharedPlanCount)")
                SplitMetricTile(title: "People", value: "\(sharedPeopleCount)")
                SplitMetricTile(title: "You Pay", value: "\(billedByYouCount)")
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .strokeBorder(DesignSystem.Colors.separator.opacity(0.2), lineWidth: 0.5)
        )
    }
}

private struct SplitMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.label)
                .monospacedDigit()

            Text(title)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

private struct ShareSetupSection: View {
    let unsharedCount: Int
    let onSetUp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Set Up a Split")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.label)

            Button(action: onSetUp) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose a subscription")
                            .font(DesignSystem.Typography.calloutEmphasized)
                            .foregroundStyle(DesignSystem.Colors.label)

                        Text("\(unsharedCount) subscription\(unsharedCount == 1 ? "" : "s") ready for participant tracking")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.secondaryGroupedBackground)
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
        .background(DesignSystem.Colors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }
}

private struct EmptyConfiguredShareCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("No split costs configured")
                .font(DesignSystem.Typography.headlineEmphasized)
                .foregroundStyle(DesignSystem.Colors.label)

            Text("Choose a subscription above to start tracking the participants and how the bill is covered.")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }
}

private struct SplitSubscriptionRow: View {
    let subscription: Subscription
    let formattedYourMonthlyShare: String
    let onTap: () -> Void

    private var shareSummary: String {
        switch subscription.activeSharingBillingMode {
        case .splitEqually:
            return "Split across \(subscription.participantCount) people"
        case .youPay:
            return "You cover the bill for \(subscription.otherParticipantsCount) other\(subscription.otherParticipantsCount == 1 ? "" : "s")"
        case .otherPays:
            if let payerName = subscription.payerMember?.name {
                return "\(payerName) pays the bill"
            }
            return "Someone else pays"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                        .frame(width: 44, height: 44)

                    Image(systemName: subscription.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(subscription.category.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(subscription.name)
                        .font(DesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text(shareSummary)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        .lineLimit(2)

                    Text("Your share: \(formattedYourMonthlyShare)/mo")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SplitSubscriptionDetailSheet: View {
    let subscription: Subscription
    let formattedYourMonthlyShare: String
    let onBillingModeChange: (SharingBillingMode) -> Void
    let onSaveMember: (SharedMember, SharedMember?) -> Void
    let onRemoveMember: (SharedMember) -> Void
    let onSetPayer: (SharedMember) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editorContext: SharedMemberEditorContext?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                    .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                                    .frame(width: 46, height: 46)

                                Image(systemName: subscription.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(subscription.category.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name)
                                    .font(DesignSystem.Typography.headlineEmphasized)
                                    .foregroundStyle(DesignSystem.Colors.label)

                                Text("\(subscription.formattedCost) per \(subscription.billingCycle.rawValue.lowercased())")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                            }
                        }

                        HStack(spacing: DesignSystem.Spacing.md) {
                            DetailMetric(title: "Your Share", value: formattedYourMonthlyShare, subtitle: "per month")
                            DetailMetric(title: "People", value: "\(subscription.participantCount)", subtitle: subscription.activeSharingBillingMode.shortLabel)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }

                Section {
                    ForEach(SharingBillingMode.allCases) { mode in
                        Button {
                            onBillingModeChange(mode)
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                Label(mode.rawValue, systemImage: mode.iconName)
                                    .foregroundStyle(DesignSystem.Colors.label)

                                Spacer()

                                if subscription.activeSharingBillingMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignSystem.Colors.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Bill Handling")
                } footer: {
                    Text(subscription.splitSummary)
                }

                Section {
                    ForEach(subscription.sharedWith) { member in
                        SharedMemberRow(
                            member: member,
                            subscription: subscription,
                            showsPayerControl: subscription.activeSharingBillingMode == .otherPays,
                            onEdit: { editorContext = SharedMemberEditorContext(member: member) },
                            onRemove: { onRemoveMember(member) },
                            onSetPayer: { onSetPayer(member) }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Button {
                        editorContext = SharedMemberEditorContext()
                    } label: {
                        Label("Add person", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("People")
                } footer: {
                    if subscription.sharedWith.isEmpty {
                        Text("Add at least one participant to start tracking the split.")
                    } else if subscription.activeSharingBillingMode == .otherPays {
                        Text("Choose one person as the payer. Everyone else is tracked as a participant.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Split Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editorContext) { context in
                SharedMemberEditorSheet(
                    subscription: subscription,
                    existingMember: context.member,
                    onSave: { member in
                        onSaveMember(member, context.member)
                    }
                )
            }
        }
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.label)
                .monospacedDigit()
                .lineLimit(1)

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

private struct SharedMemberRow: View {
    let member: SharedMember
    let subscription: Subscription
    let showsPayerControl: Bool
    let onEdit: () -> Void
    let onRemove: () -> Void
    let onSetPayer: () -> Void

    private var detailText: String {
        switch subscription.activeSharingBillingMode {
        case .splitEqually:
            let splitAmount = subscription.currency.formatAmount(subscription.cost / Double(max(subscription.participantCount, 1)))
            return "\(member.shareType.rawValue) • \(splitAmount) share"
        case .youPay:
            return "\(member.shareType.rawValue) • Covered by you"
        case .otherPays:
            return member.isPayer ? "\(member.shareType.rawValue) • Pays full bill" : "\(member.shareType.rawValue) • Participant"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
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

            if showsPayerControl {
                Button(action: onSetPayer) {
                    Image(systemName: member.isPayer ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(member.isPayer ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryLabel)
                }
                .buttonStyle(.plain)
            }

            Menu {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

struct SharedMemberEditorSheet: View {
    let subscription: Subscription
    let existingMember: SharedMember?
    let onSave: (SharedMember) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var shareType: ShareType

    init(
        subscription: Subscription,
        existingMember: SharedMember? = nil,
        onSave: @escaping (SharedMember) -> Void
    ) {
        self.subscription = subscription
        self.existingMember = existingMember
        self.onSave = onSave
        _name = State(initialValue: existingMember?.name ?? "")
        _email = State(initialValue: existingMember?.email ?? "")
        _shareType = State(initialValue: existingMember?.shareType ?? .family)
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Subscription") {
                    LabeledContent("Plan") {
                        Text(subscription.name)
                    }

                    LabeledContent("Billing") {
                        Text("\(subscription.formattedCost) per \(subscription.billingCycle.rawValue.lowercased())")
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
                            isPayer: existingMember?.isPayer ?? false,
                            addedDate: existingMember?.addedDate ?? Date()
                        )

                        onSave(member)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
            .listStyle(.insetGrouped)
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

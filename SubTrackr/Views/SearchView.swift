import SwiftUI

private enum SearchQuickFilter: String, CaseIterable, Identifiable {
    case dueSoon
    case trials
    case shared
    case annual
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueSoon: return "Due Soon"
        case .trials: return "Trials"
        case .shared: return "Shared"
        case .annual: return "Annual"
        case .archived: return "Archived"
        }
    }

    var icon: String {
        switch self {
        case .dueSoon: return "clock.badge"
        case .trials: return "sparkles"
        case .shared: return "person.2.fill"
        case .annual: return "calendar"
        case .archived: return "archivebox"
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var viewModel: SubscriptionViewModel
    @StateObject private var cloudKitService = CloudKitService.shared
    @State private var showingFilters = false
    @State private var subscriptionToDelete: Subscription?
    @State private var showingDeleteConfirmation = false
    @State private var subscriptionToEdit: Subscription?
    @State private var selectedQuickFilter: SearchQuickFilter?
    @FocusState private var isSearchFocused: Bool

    private var hasActiveCriteria: Bool {
        !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil || selectedQuickFilter != nil
    }

    private var upcomingSubscriptions: [Subscription] {
        viewModel.getUpcomingRenewals()
    }

    private var trialSubscriptions: [Subscription] {
        viewModel.subscriptions
            .filter { $0.isActive && !$0.isArchived && $0.isTrial }
            .sorted { lhs, rhs in
                (lhs.daysUntilTrialEnds ?? .max) < (rhs.daysUntilTrialEnds ?? .max)
            }
    }

    private var sharedSubscriptions: [Subscription] {
        sortedSubscriptions(
            viewModel.subscriptions.filter { $0.isActive && !$0.isArchived && $0.isSharedSubscription }
        )
    }

    private var annualSubscriptions: [Subscription] {
        sortedSubscriptions(
            viewModel.subscriptions.filter { $0.isActive && !$0.isArchived && $0.billingCycle == .annual }
        )
    }

    private var highCostSubscriptions: [Subscription] {
        sortedSubscriptions(
            viewModel.subscriptions.filter { $0.isActive && !$0.isArchived }
        ).sorted { lhs, rhs in
            monthlyCost(lhs) > monthlyCost(rhs)
        }
    }

    private var searchResultsSubscriptions: [Subscription] {
        let base: [Subscription]

        switch selectedQuickFilter {
        case .archived:
            base = filteredArchivedSubscriptions
        case .dueSoon:
            base = viewModel.filteredSubscriptions.filter { subscription in
                subscription.isActive &&
                !subscription.isArchived &&
                subscription.nextBillingDate >= Date() &&
                subscription.nextBillingDate <= (Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
            }
        case .trials:
            base = viewModel.filteredSubscriptions.filter(\.isTrial)
        case .shared:
            base = viewModel.filteredSubscriptions.filter(\.isSharedSubscription)
        case .annual:
            base = viewModel.filteredSubscriptions.filter { $0.billingCycle == .annual }
        case nil:
            base = viewModel.filteredSubscriptions
        }

        return sortedSubscriptions(base)
    }

    private var filteredArchivedSubscriptions: [Subscription] {
        var archived = viewModel.archivedSubscriptions

        if let selectedCategory = viewModel.selectedCategory {
            archived = archived.filter { $0.category == selectedCategory }
        }

        if !viewModel.searchText.isEmpty {
            let query = viewModel.searchText.localizedLowercase
            archived = archived.filter { subscription in
                subscription.name.localizedCaseInsensitiveContains(query) ||
                subscription.category.rawValue.localizedCaseInsensitiveContains(query) ||
                subscription.billingCycle.rawValue.localizedCaseInsensitiveContains(query)
            }
        }

        return archived
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    searchBar
                    quickFilterRow

                    if hasActiveFiltersVisible {
                        activeFiltersRow
                    }

                    if cloudKitService.isLoading && viewModel.subscriptions.isEmpty {
                        SearchLoadingSkeleton()
                    } else if !hasActiveCriteria {
                        discoverView
                    } else if searchResultsSubscriptions.isEmpty {
                        noResultsState
                    } else {
                        searchResults
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xxxl)
            }
            .background(DesignSystem.Colors.groupedBackground)
            .refreshable {
                CloudKitService.shared.fetchSubscriptions()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                DesignSystem.Haptics.selection()
                                withAnimation(DesignSystem.Animation.springSnappy) {
                                    viewModel.sortOption = option
                                }
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignSystem.Colors.accent)
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        DesignSystem.Haptics.light()
                        showingFilters = true
                    } label: {
                        Image(systemName: viewModel.selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignSystem.Colors.accent)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(selectedCategory: $viewModel.selectedCategory)
        }
        .sheet(item: $subscriptionToEdit) { subscription in
            EditSubscriptionView(subscription: subscription) { updatedSubscription in
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)

                TextField("Search name, category, trial, shared, annual...", text: $viewModel.searchText)
                    .font(DesignSystem.Typography.body)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .submitLabel(.search)

                if !viewModel.searchText.isEmpty {
                    Button {
                        DesignSystem.Haptics.light()
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryFill)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous))

            if hasActiveCriteria {
                Button {
                    resetSearchState()
                } label: {
                    Text("Clear")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .screenPadding()
    }

    private var quickFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(SearchQuickFilter.allCases) { filter in
                    QuickFilterButton(
                        filter: filter,
                        isSelected: selectedQuickFilter == filter
                    ) {
                        DesignSystem.Haptics.selection()
                        withAnimation(DesignSystem.Animation.springSnappy) {
                            selectedQuickFilter = selectedQuickFilter == filter ? nil : filter
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }

    private var hasActiveFiltersVisible: Bool {
        viewModel.selectedCategory != nil || selectedQuickFilter != nil
    }

    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let selectedCategory = viewModel.selectedCategory {
                    FilterChip(category: selectedCategory) {
                        DesignSystem.Haptics.light()
                        withAnimation(DesignSystem.Animation.springSnappy) {
                            viewModel.selectedCategory = nil
                        }
                    }
                }

                if let selectedQuickFilter {
                    QuickFilterTag(filter: selectedQuickFilter) {
                        DesignSystem.Haptics.light()
                        withAnimation(DesignSystem.Animation.springSnappy) {
                            self.selectedQuickFilter = nil
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Discover

    private var discoverView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
            discoveryHero

            if !upcomingSubscriptions.isEmpty {
                SearchCollectionSection(
                    title: "Renewing Soon",
                    subtitle: "Subscriptions due in the next 7 days",
                    subscriptions: Array(upcomingSubscriptions.prefix(3)),
                    searchText: viewModel.searchText,
                    onTap: handleSubscriptionTap,
                    onDelete: handleDelete
                )
            }

            if !trialSubscriptions.isEmpty {
                SearchCollectionSection(
                    title: "Trials To Review",
                    subtitle: "Catch trials before they convert",
                    subscriptions: Array(trialSubscriptions.prefix(3)),
                    searchText: viewModel.searchText,
                    onTap: handleSubscriptionTap,
                    onDelete: handleDelete
                )
            }

            if !highCostSubscriptions.isEmpty {
                SearchCollectionSection(
                    title: "Highest Monthly Cost",
                    subtitle: "Your biggest recurring subscriptions",
                    subscriptions: Array(highCostSubscriptions.prefix(3)),
                    searchText: viewModel.searchText,
                    onTap: handleSubscriptionTap,
                    onDelete: handleDelete
                )
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Browse by Category")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)

                categoryGrid
                    .screenPadding()
            }
        }
    }

    private var discoveryHero: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Find subscriptions faster")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.label)

            Text("Use quick filters for trials, renewals, shared plans, or archived subscriptions. Search also understands terms like annual, monthly, and shared.")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryGroupedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .strokeBorder(DesignSystem.Colors.separator.opacity(0.2), lineWidth: 0.5)
        )
        .screenPadding()
    }

    // MARK: - No Results

    private var noResultsState: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Results")
                    .font(DesignSystem.Typography.title2)

                Text("Try a different keyword or clear one of your filters.")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            Button {
                resetSearchState()
            } label: {
                Text("Clear All")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.top, DesignSystem.Spacing.xxxxl)
    }

    // MARK: - Search Results

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Results")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text("\(searchResultsSubscriptions.count) matching subscriptions")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }

                Spacer()
            }
            .screenPadding()

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(searchResultsSubscriptions) { subscription in
                    SearchResultRow(
                        subscription: subscription,
                        searchText: viewModel.searchText
                    ) { selectedSubscription in
                        handleSubscriptionTap(selectedSubscription)
                    }
                    .contextMenu {
                        Button {
                            subscriptionToEdit = subscription
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            handleDelete(subscription)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            handleDelete(subscription)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            subscriptionToEdit = subscription
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(DesignSystem.Colors.accent)
                    }
                }
            }
            .screenPadding()
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3), spacing: DesignSystem.Spacing.sm) {
            ForEach(SubscriptionCategory.allCases) { category in
                CategoryCard(category: category) {
                    DesignSystem.Haptics.light()
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func resetSearchState() {
        DesignSystem.Haptics.medium()
        withAnimation(DesignSystem.Animation.springSnappy) {
            viewModel.clearFilters()
            selectedQuickFilter = nil
            isSearchFocused = false
        }
    }

    private func handleSubscriptionTap(_ subscription: Subscription) {
        DesignSystem.Haptics.selection()
        subscriptionToEdit = subscription
    }

    private func handleDelete(_ subscription: Subscription) {
        subscriptionToDelete = subscription
        showingDeleteConfirmation = true
    }

    private func monthlyCost(_ subscription: Subscription) -> Double {
        let converted = CurrencyManager.shared.convertToUserCurrency(
            subscription.cost * subscription.billingCycle.monthlyEquivalent,
            from: subscription.currency
        )
        return converted
    }

    private func sortedSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        let currencyManager = CurrencyManager.shared

        switch viewModel.sortOption {
        case .nameAscending:
            return subscriptions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return subscriptions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .priceHighToLow:
            return subscriptions.sorted { lhs, rhs in
                let lhsAmount = currencyManager.convertToUserCurrency(lhs.cost * lhs.billingCycle.monthlyEquivalent, from: lhs.currency)
                let rhsAmount = currencyManager.convertToUserCurrency(rhs.cost * rhs.billingCycle.monthlyEquivalent, from: rhs.currency)
                return lhsAmount > rhsAmount
            }
        case .priceLowToHigh:
            return subscriptions.sorted { lhs, rhs in
                let lhsAmount = currencyManager.convertToUserCurrency(lhs.cost * lhs.billingCycle.monthlyEquivalent, from: lhs.currency)
                let rhsAmount = currencyManager.convertToUserCurrency(rhs.cost * rhs.billingCycle.monthlyEquivalent, from: rhs.currency)
                return lhsAmount < rhsAmount
            }
        case .nextRenewal:
            return subscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }
        case .newest:
            return subscriptions.sorted { $0.startDate > $1.startDate }
        }
    }
}

// MARK: - Filter View

struct FilterView: View {
    @Binding var selectedCategory: SubscriptionCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Select a category to filter your subscriptions")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.secondaryLabel)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                            ForEach(SubscriptionCategory.allCases) { category in
                                CategoryFilterCard(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    DesignSystem.Haptics.selection()
                                    withAnimation(DesignSystem.Animation.springSnappy) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        DesignSystem.Haptics.light()
                        withAnimation(DesignSystem.Animation.springSnappy) {
                            selectedCategory = nil
                        }
                    } label: {
                        Text("Clear")
                            .foregroundStyle(selectedCategory == nil ? DesignSystem.Colors.tertiaryLabel : DesignSystem.Colors.accent)
                    }
                    .disabled(selectedCategory == nil)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        DesignSystem.Haptics.light()
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let category: SubscriptionCategory
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .semibold))

            Text(category.rawValue)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.semibold)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.categorySubtle(category.color))
        )
        .overlay(
            Capsule()
                .strokeBorder(category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct QuickFilterButton: View {
    let filter: SearchQuickFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(filter.title)
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.label)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryGroupedBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.separator.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle(scale: 0.96, haptic: false))
    }
}

private struct QuickFilterTag: View {
    let filter: SearchQuickFilter
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: filter.icon)
                .font(.system(size: 12, weight: .semibold))

            Text(filter.title)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.semibold)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(DesignSystem.Colors.accent)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.primarySubtle)
        )
        .overlay(
            Capsule()
                .strokeBorder(DesignSystem.Colors.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: SubscriptionCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.categorySubtle(category.color))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(category.color)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(category.rawValue)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .strokeBorder(DesignSystem.Colors.separator.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle(scale: 0.94, haptic: false))
    }
}

// MARK: - Category Filter Card

struct CategoryFilterCard: View {
    let category: SubscriptionCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.categorySubtle(category.color))
                        .frame(width: 40, height: 40)

                    Image(systemName: category.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(category.color)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(category.rawValue)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.label)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(isSelected ? DesignSystem.Colors.primarySubtle : DesignSystem.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? DesignSystem.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle(scale: 0.96, haptic: false))
    }
}

private struct SearchCollectionSection: View {
    let title: String
    let subtitle: String
    let subscriptions: [Subscription]
    let searchText: String
    let onTap: (Subscription) -> Void
    let onDelete: (Subscription) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(subscriptions) { subscription in
                    SearchResultRow(
                        subscription: subscription,
                        searchText: searchText,
                        onTap: onTap
                    )
                    .contextMenu {
                        Button {
                            onTap(subscription)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            onDelete(subscription)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .screenPadding()
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let subscription: Subscription
    let searchText: String
    let onTap: (Subscription) -> Void

    private var accessibilityLabel: String {
        let currencyManager = CurrencyManager.shared
        let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
        let formattedCost = currencyManager.formatAmount(convertedCost)
        return "\(subscription.name), \(formattedCost) \(subscription.billingCycle.rawValue), \(subscription.category.rawValue) category"
    }

    private var accessibilityHint: String {
        "Double tap to edit. Swipe left to delete, swipe right to edit."
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
        Button {
            onTap(subscription)
        } label: {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.categorySubtle(subscription.category.color))
                        .frame(width: 48, height: 48)

                    Image(systemName: subscription.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(subscription.category.color)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        HighlightedText(
                            subscription.name,
                            searchText: searchText,
                            font: DesignSystem.Typography.callout.weight(.semibold),
                            foregroundColor: DesignSystem.Colors.label
                        )
                        .lineLimit(1)

                        if subscription.isTrial {
                            TrialBadge(subscription: subscription)
                        }
                    }

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        HighlightedText(
                            subscription.category.rawValue,
                            searchText: searchText,
                            font: DesignSystem.Typography.caption1,
                            foregroundColor: DesignSystem.Colors.secondaryLabel
                        )

                        Circle()
                            .fill(DesignSystem.Colors.quaternaryLabel)
                            .frame(width: 3, height: 3)

                        if subscription.isTrial, let days = subscription.daysUntilTrialEnds {
                            Text(trialEndText(days: days))
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(subscription.isTrialExpiringSoon ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                                .lineLimit(1)
                        } else {
                            Text("Next: \(subscription.nextBillingDate, style: .date)")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.sm)

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    let currencyManager = CurrencyManager.shared
                    let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)

                    Text(currencyManager.formatAmount(convertedCost))
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(subscription.billingCycle.rawValue)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                        .lineLimit(1)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .strokeBorder(DesignSystem.Colors.separator.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle(scale: 0.97, haptic: false))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

// MARK: - Trial Badge

struct TrialBadge: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: subscription.isTrialExpiringSoon ? "exclamationmark.triangle.fill" : "gift.fill")
                .font(.system(size: 8, weight: .bold))

            Text("TRIAL")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(subscription.isTrialExpiringSoon ? DesignSystem.Colors.error : .orange)
        )
    }
}

#Preview {
    SearchView()
        .environmentObject(SubscriptionViewModel())
}

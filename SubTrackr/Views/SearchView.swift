import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var viewModel: SubscriptionViewModel
    @StateObject private var cloudKitService = CloudKitService.shared
    @State private var showingFilters = false
    @State private var subscriptionToDelete: Subscription?
    @State private var showingDeleteConfirmation = false
    @State private var subscriptionToEdit: Subscription?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    searchBar

                    // Active filter chip
                    if let selectedCategory = viewModel.selectedCategory {
                        HStack {
                            FilterChip(category: selectedCategory) {
                                DesignSystem.Haptics.light()
                                withAnimation(DesignSystem.Animation.springSnappy) {
                                    viewModel.selectedCategory = nil
                                }
                            }
                            Spacer()
                        }
                        .screenPadding()
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Content
                    if cloudKitService.isLoading && viewModel.subscriptions.isEmpty {
                        SearchLoadingSkeleton()
                    } else if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                        emptySearchState
                    } else if viewModel.filteredSubscriptions.isEmpty {
                        noResultsState
                    } else {
                        searchResults
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
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
                            .font(.system(size: 24))
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
                            .font(.system(size: 24))
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
            // Search field
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.tertiaryLabel)

                TextField("Search subscriptions", text: $viewModel.searchText)
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

            // Clear filters button
            if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                Button {
                    DesignSystem.Haptics.medium()
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        viewModel.clearFilters()
                        isSearchFocused = false
                    }
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

    // MARK: - Empty State

    private var emptySearchState: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Search Subscriptions")
                        .font(DesignSystem.Typography.title2)

                    Text("Enter a name or browse categories below")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, DesignSystem.Spacing.xxxxl)

            // Quick category selection
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Browse by Category")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.label)

                categoryGrid
            }
            .screenPadding()
        }
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

                Text("Try adjusting your search or filters")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryLabel)
            }

            Button {
                DesignSystem.Haptics.light()
                withAnimation(DesignSystem.Animation.springSnappy) {
                    viewModel.clearFilters()
                }
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
        LazyVStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(viewModel.filteredSubscriptions) { subscription in
                SearchResultRow(
                    subscription: subscription,
                    searchText: viewModel.searchText
                ) { selectedSubscription in
                    DesignSystem.Haptics.selection()
                    subscriptionToEdit = selectedSubscription
                }
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        subscriptionToDelete = subscription
                        showingDeleteConfirmation = true
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
            .background(DesignSystem.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
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
            HStack(spacing: DesignSystem.Spacing.md) {
                // Subscription icon
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

                // Subscription details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        HighlightedText(
                            subscription.name,
                            searchText: searchText,
                            font: DesignSystem.Typography.callout.weight(.semibold),
                            foregroundColor: DesignSystem.Colors.label
                        )

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
                        } else {
                            Text("Next: \(subscription.nextBillingDate, style: .date)")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                }

                Spacer()

                // Cost info
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    let currencyManager = CurrencyManager.shared
                    let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)

                    Text(currencyManager.formatAmount(convertedCost))
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.label)

                    Text(subscription.billingCycle.rawValue)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
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

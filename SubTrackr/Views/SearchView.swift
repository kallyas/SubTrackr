import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchHeader
                
                if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                    emptySearchState
                } else if viewModel.filteredSubscriptions.isEmpty {
                    noResultsState
                } else {
                    searchResults
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(selectedCategory: $viewModel.selectedCategory)
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(Color.accentColor)
                }
            }
            
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search subscriptions...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Material.regularMaterial)
                )
                
                if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
            
            if let selectedCategory = viewModel.selectedCategory {
                HStack {
                    FilterChip(category: selectedCategory) {
                        viewModel.selectedCategory = nil
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Material.regularMaterial)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Search Your Subscriptions")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Enter a subscription name or use filters to find what you're looking for.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            categoryGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Try adjusting your search terms or filters.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredSubscriptions) { subscription in
                    SearchResultRow(subscription: subscription) { selectedSubscription in
                        // Navigate to subscription details or calendar day
                        // This would need navigation coordination with parent views
                    }
                }
            }
            .padding()
        }
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(SubscriptionCategory.allCases) { category in
                CategoryCard(category: category) {
                    viewModel.selectedCategory = category
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

struct FilterView: View {
    @Binding var selectedCategory: SubscriptionCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Filter by Category")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(SubscriptionCategory.allCases) { category in
                        CategoryFilterCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                    }
                    .disabled(selectedCategory == nil)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let category: SubscriptionCategory
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.caption)
            
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(category.color.opacity(0.2))
        )
        .foregroundColor(category.color)
    }
}

struct CategoryCard: View {
    let category: SubscriptionCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.regularMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryFilterCard: View {
    let category: SubscriptionCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundColor(category.color)
                    .frame(width: 24)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.1)) : AnyShapeStyle(Material.regularMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SearchResultRow: View {
    let subscription: Subscription
    let onTap: (Subscription) -> Void
    
    var body: some View {
        Button {
            onTap(subscription)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(subscription.category.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: subscription.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(subscription.category.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(subscription.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Next: \(subscription.nextBillingDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(subscription.cost, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subscription.billingCycle.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.regularMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchView()
}
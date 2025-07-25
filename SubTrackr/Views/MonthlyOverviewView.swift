import SwiftUI

struct MonthlyOverviewView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedCategory: SubscriptionCategory?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    monthlyTotalCard
                    spendingChart
                    categoryBreakdown
                    upcomingRenewals
                }
                .padding()
                .padding(.top, 8)
            }
            .navigationTitle("Monthly Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
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
    
    private var monthlyTotalCard: some View {
        VStack(spacing: 8) {
            Text("Monthly Total")
                .font(.headline)
                .foregroundColor(.secondary)
            
            CounterAnimation(value: viewModel.monthlyTotal)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(viewModel.subscriptions.filter(\.isActive).count) active subscriptions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
    
    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            if viewModel.chartData.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                CustomPieChart(
                    data: viewModel.chartData,
                    selectedCategory: selectedCategory
                )
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.chartData, id: \.category) { item in
                    CategoryRowView(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        isSelected: selectedCategory == item.category
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == item.category ? nil : item.category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
    
    private var upcomingRenewals: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Renewals")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            let upcomingSubscriptions = viewModel.getUpcomingRenewals()
            
            if upcomingSubscriptions.isEmpty {
                Text("No renewals in the next 7 days")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(upcomingSubscriptions) { subscription in
                        UpcomingRenewalRowView(subscription: subscription)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
}

struct CategoryRowView: View {
    let category: SubscriptionCategory
    let amount: Double
    let percentage: Double
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(percentage, specifier: "%.1f")% of total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyManager.shared.formatAmount(amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? category.color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? category.color : Color.clear, lineWidth: 1)
        )
    }
}

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
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(subscription.category.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: subscription.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(subscription.category.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(renewalText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let currencyManager = CurrencyManager.shared
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            
            Text(currencyManager.formatAmount(convertedCost))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }
}

struct CustomPieChart: View {
    let data: [(category: SubscriptionCategory, amount: Double, percentage: Double)]
    let selectedCategory: SubscriptionCategory?
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: 60,
                    outerRadius: 90
                )
                .fill(item.category.color)
                .opacity(selectedCategory == nil || selectedCategory == item.category ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.3), value: selectedCategory)
            }
        }
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
import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingAddSubscription = false
    @State private var selectedDate: Date?
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                weekdayHeaders
                calendarGrid
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingDayDetails) {
            if let selectedDate = viewModel.selectedDate {
                DayDetailsView(
                    date: selectedDate,
                    subscriptions: viewModel.subscriptionsForSelectedDay
                )
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            EditSubscriptionView(subscription: nil) { subscription in
                var newSubscription = subscription
                if let selectedDate = selectedDate {
                    newSubscription.startDate = selectedDate
                }
                CloudKitService.shared.saveSubscription(newSubscription)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { viewModel.navigateToMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack {
                Text(viewModel.monthName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 2) {
                    CounterAnimation(value: viewModel.monthlyTotal)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.navigateToMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var weekdayHeaders: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.calendarDays) { day in
                CalendarDayView(
                    day: day,
                    onTap: { date in
                        viewModel.selectDay(date)
                    },
                    onLongPress: { date in
                        selectedDate = date
                        showingAddSubscription = true
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
}

struct CalendarDayView: View {
    let day: CalendarDay
    let onTap: (Date) -> Void
    let onLongPress: (Date) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                if let _ = day.date, let dayNumber = day.day {
                    // Day number
                    Text("\(dayNumber)")
                        .font(.system(size: 16, weight: day.isToday ? .bold : .medium))
                        .foregroundColor(day.isToday ? .white : .primary)

                    Spacer()

                    // Subscription indicators
                    subscriptionIndicators
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(day.isToday ? Color.accentColor : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        day.isToday ? Color.clear :
                        (!day.subscriptions.isEmpty ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2)),
                        lineWidth: day.isToday ? 0 : 1
                    )
            )

            // Subscription count badge
            if !day.subscriptions.isEmpty {
                subscriptionBadge
                    .offset(x: -4, y: 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let date = day.date {
                HapticManager.shared.lightImpact()
                onTap(date)
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            if let date = day.date {
                HapticManager.shared.mediumImpact()
                onLongPress(date)
            }
        }
    }

    // Badge showing subscription count
    private var subscriptionBadge: some View {
        Text("\(day.subscriptions.count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 18, minHeight: 18)
            .background(
                Circle()
                    .fill(badgeColor)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    // Color based on subscription count
    private var badgeColor: Color {
        switch day.subscriptions.count {
        case 1:
            return .green
        case 2:
            return .orange
        case 3...5:
            return .red
        default:
            return .purple
        }
    }

    // Visual indicators showing category colors
    private var subscriptionIndicators: some View {
        HStack(spacing: 2) {
            ForEach(Array(day.subscriptions.prefix(4)), id: \.id) { subscription in
                Circle()
                    .fill(subscription.category.color)
                    .frame(width: 6, height: 6)
            }

            if day.subscriptions.count > 4 {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    CalendarView()
}
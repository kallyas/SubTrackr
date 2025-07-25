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
        VStack(spacing: 2) {
            if let _ = day.date, let dayNumber = day.day {
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: day.isToday ? .bold : .medium))
                    .foregroundColor(day.isToday ? .white : .primary)
                
                subscriptionIcons
            }
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
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
    
    private var subscriptionIcons: some View {
        HStack(spacing: 1) {
            ForEach(Array(day.subscriptions.prefix(3)), id: \.id) { subscription in
                AnimatedIconView(subscription: subscription)
            }
            
            if day.subscriptions.count > 3 {
                Text("+\(day.subscriptions.count - 3)")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    CalendarView()
}
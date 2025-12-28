import Foundation
import Combine
import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDate: Date?
    @Published var subscriptionsForSelectedDay: [Subscription] = []
    @Published var showingDayDetails = false
    @Published var monthlyTotal: Double = 0
    
    private let cloudKitService = CloudKitService.shared
    private let currencyManager = CurrencyManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with current data
        updateMonthlyTotal()
        
        cloudKitService.$subscriptions
            .sink { [weak self] _ in
                self?.updateMonthlyTotal()
                self?.updateSelectedDaySubscriptions()
            }
            .store(in: &cancellables)
        
        // Listen for currency changes and update totals
        currencyManager.$selectedCurrency
            .sink { [weak self] _ in
                self?.updateMonthlyTotal()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    var currentMonth: Int {
        Calendar.current.component(.month, from: currentDate)
    }
    
    var currentYear: Int {
        Calendar.current.component(.year, from: currentDate)
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        let range = calendar.range(of: .day, in: .month, for: currentDate) ?? 1..<32
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
        
        var days: [CalendarDay] = []
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(date: nil, subscriptions: []))
        }
        
        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let subscriptions = getSubscriptionsForDay(day)
                days.append(CalendarDay(date: date, subscriptions: subscriptions))
            }
        }
        
        return days
    }
    
    func getSubscriptionsForDay(_ day: Int) -> [Subscription] {
        return cloudKitService.getSubscriptionsForDay(day, month: currentMonth, year: currentYear)
    }
    
    func selectDay(_ date: Date) {
        selectedDate = date
        updateSelectedDaySubscriptions()
        showingDayDetails = true
    }
    
    func navigateToMonth(_ direction: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = Calendar.current.date(byAdding: .month, value: direction, to: currentDate) ?? currentDate
        }
    }
    
    func navigateToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = Date()
        }
    }

    /// Get calendar days for a specific month offset from current month
    func getDaysForMonth(offset: Int) -> [CalendarDay] {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .month, value: offset, to: currentDate) ?? currentDate
        let startOfMonth = calendar.dateInterval(of: .month, for: targetDate)?.start ?? targetDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 30
        let targetMonth = calendar.component(.month, from: targetDate)
        let targetYear = calendar.component(.year, from: targetDate)

        var days: [CalendarDay] = []

        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(date: nil, subscriptions: []))
        }

        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let subscriptions = cloudKitService.getSubscriptionsForDay(day, month: targetMonth, year: targetYear)
                days.append(CalendarDay(date: date, subscriptions: subscriptions))
            }
        }

        return days
    }

    private func updateSelectedDaySubscriptions() {
        guard let selectedDate = selectedDate else {
            subscriptionsForSelectedDay = []
            return
        }
        
        let day = Calendar.current.component(.day, from: selectedDate)
        subscriptionsForSelectedDay = getSubscriptionsForDay(day)
    }
    
    private func updateMonthlyTotal() {
        let activeSubscriptions = cloudKitService.subscriptions.filter { $0.isActive }
        let currencyManager = CurrencyManager.shared
        
        monthlyTotal = activeSubscriptions.reduce(0) { total, subscription in
            let monthlyCostInOriginalCurrency = subscription.cost * subscription.billingCycle.monthlyEquivalent
            let convertedCost = currencyManager.convertToUserCurrency(monthlyCostInOriginalCurrency, from: subscription.currency)
            return total + convertedCost
        }
    }
    
    func getTotalForDay(_ day: Int) -> Double {
        let subscriptions = getSubscriptionsForDay(day)
        let currencyManager = CurrencyManager.shared
        
        return subscriptions.reduce(0) { total, subscription in
            let convertedCost = currencyManager.convertToUserCurrency(subscription.cost, from: subscription.currency)
            return total + convertedCost
        }
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let subscriptions: [Subscription]
    
    var day: Int? {
        guard let date = date else { return nil }
        return Calendar.current.component(.day, from: date)
    }
    
    var isToday: Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}
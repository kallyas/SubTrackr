import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingAddSubscription = false
    @State private var selectedDate: Date?
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header
                headerView
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .zIndex(1)

                // Scrollable calendar pages
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.xxl) {
                            // Previous month (above)
                            CalendarMonthView(
                                viewModel: viewModel,
                                monthOffset: -1,
                                weekdays: weekdays,
                                columns: columns,
                                onDayTap: handleDayTap,
                                onDayLongPress: handleDayLongPress
                            )
                            .id("previous")
                            .opacity(0.4)

                            // Current month
                            CalendarMonthView(
                                viewModel: viewModel,
                                monthOffset: 0,
                                weekdays: weekdays,
                                columns: columns,
                                onDayTap: handleDayTap,
                                onDayLongPress: handleDayLongPress
                            )
                            .id("current")

                            // Next month (below) - PREVIEW
                            CalendarMonthView(
                                viewModel: viewModel,
                                monthOffset: 1,
                                weekdays: weekdays,
                                columns: columns,
                                onDayTap: handleDayTap,
                                onDayLongPress: handleDayLongPress
                            )
                            .id("next")
                            .opacity(0.4)
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                    .scrollDisabled(isAnimating)
                    .onAppear {
                        // Scroll to current month on appear
                        proxy.scrollTo("current", anchor: .top)
                    }
                    .onChange(of: viewModel.currentDate) { _, _ in
                        // Smooth scroll to current month when date changes
                        withAnimation(DesignSystem.Animation.springSmooth) {
                            proxy.scrollTo("current", anchor: .top)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            if !isAnimating {
                                handleSwipe(translation: value.translation.height)
                            }
                        }
                )
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingDayDetails) {
            if let selectedDate = viewModel.selectedDate {
                DayDetailsView(
                    date: selectedDate,
                    subscriptions: viewModel.subscriptionsForSelectedDay
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            // Month and Year with cool animation
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(viewModel.monthName)
                    .font(DesignSystem.Typography.largeTitleRounded)
                    .id("month-\(viewModel.monthName)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                HStack(spacing: DesignSystem.Spacing.xs) {
                    CounterAnimation(value: viewModel.monthlyTotal)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                    Text("this month")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                }
            }

            Spacer()

            // Today button
            Button(action: jumpToToday) {
                Text("Today")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.accent)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primarySubtle)
                    .clipShape(Capsule())
            }
            .buttonStyle(InteractiveScaleButtonStyle(scale: 0.95, haptic: true))
        }
        .screenPadding()
    }

    // MARK: - Gesture Handlers

    private func handleSwipe(translation: CGFloat) {
        isAnimating = true
        DesignSystem.Haptics.light()

        if translation > 50 {
            // Swipe down - go to previous month
            viewModel.navigateToMonth(-1)
        } else if translation < -50 {
            // Swipe up - go to next month
            viewModel.navigateToMonth(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAnimating = false
        }
    }

    private func jumpToToday() {
        DesignSystem.Haptics.medium()
        withAnimation(DesignSystem.Animation.springBouncy) {
            viewModel.navigateToToday()
        }
    }

    private func handleDayTap(date: Date) {
        DesignSystem.Haptics.selection()
        viewModel.selectDay(date)
    }

    private func handleDayLongPress(date: Date) {
        DesignSystem.Haptics.medium()
        selectedDate = date
        showingAddSubscription = true
    }
}

// MARK: - Calendar Month View Component

struct CalendarMonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let monthOffset: Int
    let weekdays: [String]
    let columns: [GridItem]
    let onDayTap: (Date) -> Void
    let onDayLongPress: (Date) -> Void

    // Cached DateFormatter for performance
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private var displayDays: [CalendarDay] {
        viewModel.getDaysForMonth(offset: monthOffset)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Month label for preview months
            if monthOffset != 0 {
                monthLabel
                    .padding(.top, DesignSystem.Spacing.md)
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(DesignSystem.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(monthOffset == 0 ? DesignSystem.Colors.secondaryLabel : DesignSystem.Colors.tertiaryLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .screenPadding()

            Divider()
                .opacity(monthOffset == 0 ? 1 : 0.5)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.xs) {
                ForEach(displayDays) { day in
                    CalendarDayView(
                        day: day,
                        isPreview: monthOffset != 0,
                        onTap: onDayTap,
                        onLongPress: onDayLongPress
                    )
                }
            }
            .screenPadding()
        }
    }

    private var monthLabel: some View {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .month, value: monthOffset, to: viewModel.currentDate) ?? viewModel.currentDate

        return HStack {
            Text(Self.monthYearFormatter.string(from: targetDate))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            Spacer()
        }
    }
}

// MARK: - Calendar Day Cell (Enhanced)

struct CalendarDayView: View {
    let day: CalendarDay
    let isPreview: Bool
    let onTap: (Date) -> Void
    let onLongPress: (Date) -> Void

    @State private var isPressed = false

    private var accessibilityLabel: String {
        guard let date = day.date, let dayNumber = day.day else {
            return "Empty"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        var label = formatter.string(from: date)
        if day.isToday {
            label = "Today, \(label)"
        }
        if !day.subscriptions.isEmpty {
            label += ", \(day.subscriptions.count) subscription\(day.subscriptions.count > 1 ? "s" : "")"
        }
        return label
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if let _ = day.date, let dayNumber = day.day {
                // Day number with optional circle for today
                ZStack {
                    // Today indicator - filled circle like iOS Calendar
                    if day.isToday && !isPreview {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(dayNumber)")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(day.isToday && !isPreview ? .bold : .regular)
                        .foregroundStyle(dayTextColor)
                }
                .frame(height: 32)

                // Subscription dots (like iOS Calendar event dots)
                subscriptionDots
                    .frame(height: 6)
            } else {
                // Empty cell for days outside current month
                Color.clear
                    .frame(height: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .opacity(isPreview ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignSystem.Animation.springSnappy, value: isPressed)
        .onTapGesture {
            if let date = day.date, !isPreview {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
                onTap(date)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            if let date = day.date, !isPreview {
                onLongPress(date)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(day.date != nil && !isPreview ? "Double tap to view details. Long press to add subscription." : "")
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    // MARK: - Text Color

    private var dayTextColor: Color {
        if day.isToday && !isPreview {
            return .white
        }
        return DesignSystem.Colors.label
    }

    // MARK: - Subscription Dots (iOS Style)

    private var subscriptionDots: some View {
        HStack(spacing: 2) {
            if !day.subscriptions.isEmpty {
                ForEach(Array(day.subscriptions.prefix(4)), id: \.id) { subscription in
                    Circle()
                        .fill(day.isToday && !isPreview ? .white.opacity(0.8) : subscription.category.color)
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}

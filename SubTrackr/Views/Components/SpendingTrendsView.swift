//
//  SpendingTrendsView.swift
//  SubTrackr
//
//  Component for displaying spending trends over time
//

import SwiftUI

struct SpendingTrendsView: View {
    let monthlyData: [MonthlySpending]
    @State private var selectedPeriod: TrendPeriod = .threeMonths

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header with period selector
            HStack {
                Text("Spending Trends")
                    .font(DesignSystem.Typography.headline)

                Spacer()

                periodPicker
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)

            if filteredData.isEmpty {
                emptyState
            } else {
                // Trend chart
                trendChart
                    .frame(height: 180)
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                // Statistics
                trendStatistics
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.lg)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }

    private var periodPicker: some View {
        Menu {
            ForEach(TrendPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    HStack {
                        Text(period.title)
                        if selectedPeriod == period {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedPeriod.title)
                    .font(DesignSystem.Typography.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(DesignSystem.Colors.accent)
        }
    }

    private var filteredData: [MonthlySpending] {
        let count = selectedPeriod.monthCount
        return Array(monthlyData.suffix(count))
    }

    private var trendChart: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                gridLines(in: geometry.size)

                // Line chart
                lineChart(in: geometry.size)
                    .stroke(DesignSystem.Colors.accent, lineWidth: 2.5)
                    .shadow(color: DesignSystem.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)

                // Data points
                dataPoints(in: geometry.size)

                // Gradient fill
                gradientFill(in: geometry.size)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.3),
                                DesignSystem.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            let horizontalLines = 4
            for i in 0...horizontalLines {
                let y = CGFloat(i) * (size.height / CGFloat(horizontalLines))
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
    }

    private func lineChart(in size: CGSize) -> Path {
        Path { path in
            guard !filteredData.isEmpty else { return }

            let maxValue = filteredData.map(\.amount).max() ?? 0
            guard maxValue > 0 else { return }

            let points = filteredData.enumerated().map { index, data -> CGPoint in
                let x = CGFloat(index) * (size.width / CGFloat(max(filteredData.count - 1, 1)))
                let normalizedValue = data.amount / maxValue
                let y = size.height - (normalizedValue * size.height)
                return CGPoint(x: x, y: y)
            }

            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func dataPoints(in size: CGSize) -> some View {
        let maxValue = filteredData.map(\.amount).max() ?? 0

        return ZStack {
            if maxValue > 0 {
                ForEach(Array(filteredData.enumerated()), id: \.offset) { index, data in
                    let x = CGFloat(index) * (size.width / CGFloat(max(filteredData.count - 1, 1)))
                    let normalizedValue = data.amount / maxValue
                    let y = size.height - (normalizedValue * size.height)

                    Circle()
                        .fill(DesignSystem.Colors.accent)
                        .frame(width: 6, height: 6)
                        .shadow(color: DesignSystem.Colors.accent.opacity(0.5), radius: 3, x: 0, y: 1)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func gradientFill(in size: CGSize) -> Path {
        Path { path in
            guard !filteredData.isEmpty else { return }

            let maxValue = filteredData.map(\.amount).max() ?? 0
            guard maxValue > 0 else { return }

            let points = filteredData.enumerated().map { index, data -> CGPoint in
                let x = CGFloat(index) * (size.width / CGFloat(max(filteredData.count - 1, 1)))
                let normalizedValue = data.amount / maxValue
                let y = size.height - (normalizedValue * size.height)
                return CGPoint(x: x, y: y)
            }

            guard let firstPoint = points.first, let lastPoint = points.last else { return }

            path.move(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            // Close the path at the bottom
            path.addLine(to: CGPoint(x: lastPoint.x, y: size.height))
            path.addLine(to: CGPoint(x: firstPoint.x, y: size.height))
            path.closeSubpath()
        }
    }

    private var trendStatistics: some View {
        HStack(spacing: DesignSystem.Spacing.xl) {
            statisticItem(
                title: "Average",
                value: averageSpending,
                icon: "chart.bar.fill",
                color: DesignSystem.Colors.info
            )

            Divider()
                .frame(height: 40)

            statisticItem(
                title: "Highest",
                value: highestSpending,
                icon: "arrow.up.circle.fill",
                color: DesignSystem.Colors.error
            )

            Divider()
                .frame(height: 40)

            statisticItem(
                title: "Trend",
                value: trendPercentage,
                icon: trendIcon,
                color: trendColor,
                isPercentage: true
            )
        }
    }

    private func statisticItem(
        title: String,
        value: Double,
        icon: String,
        color: Color,
        isPercentage: Bool = false
    ) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }

            if isPercentage {
                Text("\(value >= 0 ? "+" : "")\(value, specifier: "%.1f")%")
                    .font(DesignSystem.Typography.bodyEmphasized)
            } else {
                Text(CurrencyManager.shared.formatAmount(value))
                    .font(DesignSystem.Typography.bodyEmphasized)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.secondaryLabel)

            Text("Not enough data")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryLabel)

            Text("Add subscriptions to see spending trends")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }

    // Computed properties
    private var averageSpending: Double {
        guard !filteredData.isEmpty else { return 0 }
        return filteredData.map(\.amount).reduce(0, +) / Double(filteredData.count)
    }

    private var highestSpending: Double {
        filteredData.map(\.amount).max() ?? 0
    }

    private var trendPercentage: Double {
        guard filteredData.count >= 2 else { return 0 }
        let firstHalf = filteredData.prefix(filteredData.count / 2)
        let secondHalf = filteredData.suffix(filteredData.count / 2)

        let firstAverage = firstHalf.map(\.amount).reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.map(\.amount).reduce(0, +) / Double(secondHalf.count)

        guard firstAverage > 0 else { return 0 }
        return ((secondAverage - firstAverage) / firstAverage) * 100
    }

    private var trendIcon: String {
        if trendPercentage > 0 {
            return "arrow.up.right.circle.fill"
        } else if trendPercentage < 0 {
            return "arrow.down.right.circle.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }

    private var trendColor: Color {
        if trendPercentage > 5 {
            return DesignSystem.Colors.error
        } else if trendPercentage < -5 {
            return DesignSystem.Colors.success
        } else {
            return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Supporting Types

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
    let date: Date
}

enum TrendPeriod: CaseIterable {
    case threeMonths
    case sixMonths
    case year

    var title: String {
        switch self {
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "12 Months"
        }
    }

    var monthCount: Int {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .year: return 12
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleData = Array((0..<6).map { index in
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .month, value: -index, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return MonthlySpending(
            month: formatter.string(from: date),
            amount: Double.random(in: 50...200),
            date: date
        )
    }.reversed())

    ScrollView {
        SpendingTrendsView(monthlyData: sampleData)
            .padding()
    }
}

import SwiftUI

/// A shimmer effect modifier for skeleton loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Skeleton placeholder shapes
struct SkeletonShape: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(
        width: CGFloat? = nil,
        height: CGFloat = 16,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.xs
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DesignSystem.Colors.tertiaryFill)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// Skeleton for a subscription row
struct SubscriptionRowSkeleton: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon placeholder
            Circle()
                .fill(DesignSystem.Colors.tertiaryFill)
                .frame(width: 48, height: 48)
                .shimmer()

            // Text placeholders
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonShape(width: 120, height: 16)
                SkeletonShape(width: 80, height: 12)
            }

            Spacer()

            // Price placeholder
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                SkeletonShape(width: 60, height: 16)
                SkeletonShape(width: 40, height: 12)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

/// Skeleton for the monthly total card
struct MonthlyTotalSkeleton: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                SkeletonShape(width: 150, height: 40, cornerRadius: DesignSystem.CornerRadius.sm)
                SkeletonShape(width: 80, height: 16)
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Circle()
                    .fill(DesignSystem.Colors.tertiaryFill)
                    .frame(width: 16, height: 16)
                    .shimmer()
                SkeletonShape(width: 60, height: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

/// Skeleton for the pie chart
struct PieChartSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    SkeletonShape(width: 160, height: 20)
                    SkeletonShape(width: 80, height: 14)
                }
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)

            // Chart placeholder
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.tertiaryFill, lineWidth: 30)
                        .frame(width: 170, height: 170)
                        .shimmer()

                    Circle()
                        .fill(DesignSystem.Colors.secondaryBackground)
                        .frame(width: 110, height: 110)
                }
                Spacer()
            }
            .frame(height: 220)
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

/// Skeleton for category breakdown
struct CategoryBreakdownSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            SkeletonShape(width: 100, height: 20)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)

            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<3, id: \.self) { _ in
                    CategoryRowSkeleton()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

/// Skeleton for a category row
struct CategoryRowSkeleton: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Colors.tertiaryFill)
                .frame(width: 40, height: 40)
                .shimmer()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                SkeletonShape(width: 80, height: 16)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    SkeletonShape(width: 60, height: 4)
                    SkeletonShape(width: 30, height: 12)
                }
            }

            Spacer()

            SkeletonShape(width: 50, height: 16)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
    }
}

/// Full loading state for Overview screen
struct OverviewLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            MonthlyTotalSkeleton()
            PieChartSkeleton()
            CategoryBreakdownSkeleton()
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
        .screenPadding()
    }
}

/// Full loading state for Search screen
struct SearchLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<5, id: \.self) { _ in
                SubscriptionRowSkeleton()
            }
        }
        .screenPadding()
    }
}

#Preview("Subscription Row") {
    VStack(spacing: 16) {
        SubscriptionRowSkeleton()
        SubscriptionRowSkeleton()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Monthly Total") {
    MonthlyTotalSkeleton()
        .padding()
}

#Preview("Overview Loading") {
    ScrollView {
        OverviewLoadingSkeleton()
    }
    .background(DesignSystem.Colors.background)
}

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -5
    @State private var shimmerOffset: CGFloat = -200

    var onAnimationComplete: () -> Void

    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.secondaryBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.xxl) {
                // App Icon Container
                ZStack {
                    // Subtle glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignSystem.Colors.accent.opacity(0.15),
                                    DesignSystem.Colors.accent.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .opacity(logoOpacity)

                    // App Icon
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.accent,
                                    DesignSystem.Colors.accent.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            // Inner icon content
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                // Stylized subscription icon
                                ZStack {
                                    // Card background
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(.white.opacity(0.95))
                                        .frame(width: 44, height: 28)

                                    VStack(spacing: 2) {
                                        // Card chip circles
                                        HStack(spacing: 3) {
                                            Circle()
                                                .fill(DesignSystem.Colors.accent.opacity(0.4))
                                                .frame(width: 4, height: 4)
                                            Circle()
                                                .fill(DesignSystem.Colors.accent.opacity(0.4))
                                                .frame(width: 4, height: 4)
                                            Circle()
                                                .fill(DesignSystem.Colors.accent.opacity(0.4))
                                                .frame(width: 4, height: 4)
                                        }
                                        .offset(y: -2)
                                    }
                                }
                                .offset(y: -6)

                                // Currency symbol
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .symbolRenderingMode(.hierarchical)
                                    .offset(y: 8)
                            }
                        )
                        .overlay(
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous))
                        .softShadow()
                        .scaleEffect(logoScale)
                        .rotationEffect(.degrees(iconRotation))
                        .opacity(logoOpacity)
                }

                // App Name
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("SubTrackr")
                        .font(DesignSystem.Typography.displayMedium)
                        .foregroundStyle(DesignSystem.Colors.label)
                        .opacity(textOpacity)

                    Text("Track Your Subscriptions")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        // Logo entrance with spring animation
        withAnimation(DesignSystem.Animation.springSmooth.delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
            iconRotation = 0
        }

        // Text fade in
        withAnimation(DesignSystem.Animation.gentle.delay(0.4)) {
            textOpacity = 1.0
        }

        // Shimmer effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 0.8)) {
                shimmerOffset = 300
            }
        }

        // Complete and transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            DesignSystem.Haptics.light()
            withAnimation(DesignSystem.Animation.standard) {
                onAnimationComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Animation completed")
    }
}

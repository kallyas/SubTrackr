import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 15
    @State private var shimmerOffset: CGFloat = -200
    @State private var glowOpacity: Double = 0
    
    var onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                logoSection
                
                textSection
                
                Spacer()
                
                loadingSection
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private var logoSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.accent.opacity(0.2),
                            DesignSystem.Colors.accent.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .opacity(glowOpacity)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.accent.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .opacity(glowOpacity)
            
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.accent,
                            DesignSystem.Colors.accent.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    iconContent
                )
                .overlay(
                    shimmerOverlay
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous))
                .softShadow(color: DesignSystem.Colors.accent.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
    }
    
    private var iconContent: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white.opacity(0.95))
                    .frame(width: 38, height: 24)
                
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.3))
                            .frame(width: 4, height: 4)
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.3))
                            .frame(width: 4, height: 4)
                        Circle()
                            .fill(DesignSystem.Colors.accent.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
                .offset(y: -2)
            }
            .offset(y: -5)
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
                .offset(y: 6)
        }
    }
    
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.hero, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.25),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(x: shimmerOffset)
    }
    
    private var textSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("SubTrackr")
                .font(DesignSystem.Typography.displayMedium)
                .foregroundStyle(DesignSystem.Colors.label)
                .offset(y: textOffset)
                .opacity(textOpacity)
            
            Text("Track Your Subscriptions")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.secondaryLabel)
                .offset(y: textOffset)
                .opacity(textOpacity)
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                .scaleEffect(0.9)
            
            Text("Loading your subscriptions...")
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
        }
        .padding(.bottom, DesignSystem.Spacing.xxxl)
    }
    
    private func startAnimationSequence() {
        withAnimation(DesignSystem.Animation.springSmooth.delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
            glowOpacity = 1.0
        }
        
        withAnimation(DesignSystem.Animation.gentle.delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.linear(duration: 0.8)) {
                shimmerOffset = 300
            }
        }
        
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

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showingApp = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                logoView
                
                textView
                
                Spacer()
                
                loadingView
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showingApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingApp) {
            ContentView()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.12, blue: 0.20),
                Color(red: 0.12, green: 0.08, blue: 0.18),
                Color(red: 0.06, green: 0.10, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.15),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )
        )
        .overlay(
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.clear
                            ],
                            center: .bottomLeading,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.6
                        )
                    )
                    .offset(x: -geometry.size.width * 0.3, y: geometry.size.height * 0.3)
            }
        )
    }
    
    private var logoView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.accentColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: isAnimating ? 30 : 50)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(isAnimating ? 1.0 : 0.9)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    private var textView: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("SubTrackr")
                .font(DesignSystem.Typography.displayLarge)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .white,
                            .white.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: textOffset)
                .opacity(textOpacity)
            
            Text("Track Your Subscriptions")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .offset(y: textOffset)
                .opacity(textOpacity)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                .scaleEffect(0.8)
            
            Text("Loading...")
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(.white.opacity(0.4))
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .padding(.bottom, DesignSystem.Spacing.xxxl)
    }
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOffset = 0
            textOpacity = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            isAnimating = true
        }
    }
}

#Preview {
    LaunchScreenView()
}

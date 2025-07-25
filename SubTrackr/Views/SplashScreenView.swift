import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var backgroundGradientOpacity: Double = 0
    @State private var pulseAnimation: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var showParticles: Bool = false
    
    var onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background gradient
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .opacity(backgroundGradientOpacity)
            .ignoresSafeArea()
            
            // Particle effect background
            if showParticles {
                ParticleSystemView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 24) {
                // Main logo container
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(logoOpacity)
                    
                    // Inner circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .opacity(logoOpacity)
                    
                    // App icon/logo
                    ZStack {
                        // Background circle for icon
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        // Subscription tracking icon
                        VStack(spacing: 2) {
                            // Credit card icon
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 32, height: 20)
                                .overlay(
                                    HStack(spacing: 2) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 4, height: 4)
                                        Circle()
                                            .fill(Color.purple)
                                            .frame(width: 4, height: 4)
                                        Circle()
                                            .fill(Color.pink)
                                            .frame(width: 4, height: 4)
                                    }
                                    .offset(y: -2)
                                )
                            
                            // Dollar sign
                            Text("$")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotationEffect(.degrees(rotationAngle))
                }
                
                // App name and tagline
                VStack(spacing: 8) {
                    Text("SubTrackr")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)
                    
                    Text("Track Your Subscriptions")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Stage 1: Background fade in
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundGradientOpacity = 1.0
        }
        
        // Stage 2: Logo scale and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        
        // Stage 3: Logo rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.0)) {
                rotationAngle = 360
            }
        }
        
        // Stage 4: Pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        
        // Stage 5: Text fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
            }
        }
        
        // Stage 6: Particle effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showParticles = true
        }
        
        // Stage 7: Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                onAnimationComplete()
            }
        }
    }
}

struct ParticleSystemView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                color: [Color.blue, Color.purple, Color.pink, Color.white].randomElement() ?? Color.blue,
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in particles.indices {
                withAnimation(.linear(duration: 2.0)) {
                    particles[i].position.x += CGFloat.random(in: -2...2)
                    particles[i].position.y += CGFloat.random(in: -2...2)
                    particles[i].opacity = Double.random(in: 0.1...0.9)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    SplashScreenView {
        print("Animation completed")
    }
}
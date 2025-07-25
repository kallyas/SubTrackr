import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showingApp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // App Name
                VStack(spacing: 8) {
                    Text("SubTrackr")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Track Your Subscriptions")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(isAnimating ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 1.5).delay(0.5), value: isAnimating)
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("Loading your subscriptions...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0).delay(1.0), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
            
            // Simulate loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingApp) {
            ContentView()
        }
    }
}

#Preview {
    LaunchScreenView()
}
import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            iconContainer
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.12, blue: 0.22),
                Color(red: 0.08, green: 0.10, blue: 0.18),
                Color(red: 0.12, green: 0.08, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconContainer: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.25),
                            Color.accentColor.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
            
            RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.85),
                            Color.accentColor.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.45, height: size * 0.45)
                .overlay(iconContent)
                .shadow(color: Color.accentColor.opacity(0.4), radius: size * 0.08, x: 0, y: size * 0.04)
        }
    }
    
    private var iconContent: some View {
        VStack(spacing: size * 0.01) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.018, style: .continuous)
                    .fill(.white.opacity(0.95))
                    .frame(width: size * 0.17, height: size * 0.11)
                
                VStack(spacing: size * 0.008) {
                    HStack(spacing: size * 0.008) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.accentColor.opacity(0.35))
                                .frame(width: size * 0.018, height: size * 0.018)
                        }
                    }
                }
                .offset(y: -size * 0.008)
            }
            .offset(y: -size * 0.022)
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: size * 0.10, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .offset(y: size * 0.028)
        }
    }
}

#Preview {
    AppIconView()
        .frame(width: 180, height: 180)
}

import SwiftUI

struct AnimatedIconView: View {
    let subscription: Subscription
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Image(systemName: subscription.iconName)
            .font(.system(size: 8))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        subscription.category.color,
                        subscription.category.color.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(pulseScale)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                Animation
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                withAnimation {
                    isAnimating = true
                    pulseScale = 1.1
                }
            }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: isPressed ? 5 : 10,
                            x: 0,
                            y: isPressed ? 2 : 5
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PressedButtonStyle { pressed in
            isPressed = pressed
        })
    }
}

struct PressedButtonStyle: ButtonStyle {
    let onPressedChanged: (Bool) -> Void
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.easeInOut(duration: 0.1)) {
                    onPressedChanged(pressed)
                }
            }
    }
}

struct ShimmerEffect: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.6),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct LoadingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(width: 100, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.regularMaterial)
        )
        .overlay(
            ShimmerEffect()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .clipped()
    }
}

struct SpringButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PressedButtonStyle { pressed in
            isPressed = pressed
        })
    }
}

struct CounterAnimation: View {
    let value: Double
    @State private var animatedValue: Double = 0
    
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }
    
    var body: some View {
        Text(formatter.string(from: NSNumber(value: animatedValue)) ?? "$0.00")
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedValue = newValue
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedIconView(
            subscription: Subscription(
                name: "Netflix",
                cost: 13.99,
                billingCycle: .monthly,
                startDate: Date(),
                category: .streaming
            )
        )
        
        FloatingActionButton { }
        
        LoadingCardView()
        
        CounterAnimation(value: 127.50)
    }
    .padding()
}
import SwiftUI

/// A reusable undo banner that appears after destructive actions
struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text(message)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.medium)
                .foregroundStyle(.white)

            Spacer()

            Button(action: {
                DesignSystem.Haptics.medium()
                onUndo()
            }) {
                Text("Undo")
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
            }
            .buttonStyle(InteractiveScaleButtonStyle(scale: 0.95, haptic: false))
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            Spacer()
            UndoBanner(message: "Netflix deleted", onUndo: {})
                .padding()
        }
    }
}

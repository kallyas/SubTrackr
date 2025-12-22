//
//  DesignTokens.swift
//  SubTrackr
//
//  Design system tokens for consistent UI across the app
//

import SwiftUI

/// Central design system for SubTrackr app
/// Provides consistent spacing, typography, colors, and other design tokens
enum DesignSystem {

    // MARK: - Spacing

    enum Spacing {
        /// 4pt - Extra small spacing for tight layouts
        static let xs: CGFloat = 4

        /// 8pt - Small spacing for compact elements
        static let sm: CGFloat = 8

        /// 12pt - Medium-small spacing
        static let md: CGFloat = 12

        /// 16pt - Standard spacing (default)
        static let lg: CGFloat = 16

        /// 20pt - Large spacing for section separation
        static let xl: CGFloat = 20

        /// 24pt - Extra large spacing
        static let xxl: CGFloat = 24

        /// 32pt - Huge spacing for major sections
        static let xxxl: CGFloat = 32

        /// Standard padding for screen edges
        static let screenPadding: CGFloat = 16

        /// Standard card padding
        static let cardPadding: CGFloat = 16

        /// Grid spacing for calendar and grids
        static let gridSpacing: CGFloat = 8
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        /// 4pt - Extra small radius
        static let xs: CGFloat = 4

        /// 8pt - Small radius for buttons and tags
        static let sm: CGFloat = 8

        /// 12pt - Medium radius for cards
        static let md: CGFloat = 12

        /// 16pt - Large radius for prominent cards
        static let lg: CGFloat = 16

        /// 20pt - Extra large radius
        static let xl: CGFloat = 20

        /// 24pt - Huge radius for special elements
        static let xxl: CGFloat = 24

        /// Fully rounded (circular)
        static let full: CGFloat = 1000
    }

    // MARK: - Typography

    enum Typography {
        // Display - Large headings
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

        // Title - Section headers
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .semibold)
        static let title3 = Font.system(size: 20, weight: .semibold)

        // Headline - Important text
        static let headline = Font.system(size: 17, weight: .semibold)

        // Body - Standard text
        static let body = Font.system(size: 17, weight: .regular)
        static let bodyEmphasized = Font.system(size: 17, weight: .medium)

        // Callout - Secondary text
        static let callout = Font.system(size: 16, weight: .regular)

        // Subheadline - Tertiary text
        static let subheadline = Font.system(size: 15, weight: .regular)

        // Footnote - Small text
        static let footnote = Font.system(size: 13, weight: .regular)

        // Caption - Tiny text
        static let caption1 = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)

        // Monospaced for numbers
        static let monospacedBody = Font.system(size: 17, weight: .regular, design: .monospaced)
        static let monospacedTitle = Font.system(size: 22, weight: .semibold, design: .monospaced)
    }

    // MARK: - Colors

    enum Colors {
        // Primary colors
        static let primary = Color.blue
        static let primaryDark = Color.blue.opacity(0.8)
        static let primaryLight = Color.blue.opacity(0.2)

        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Background colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)

        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(UIColor.tertiaryLabel)

        // Category colors (matching subscription categories)
        static let streaming = Color.red
        static let software = Color.blue
        static let fitness = Color.green
        static let gaming = Color.purple
        static let utilities = Color.orange
        static let news = Color.gray
        static let music = Color.pink
        static let productivity = Color.teal
        static let other = Color.brown

        // Overlay colors
        static let overlay = Color.black.opacity(0.4)
        static let cardOverlay = Color.black.opacity(0.05)

        // Border colors
        static let border = Color(UIColor.separator)
        static let divider = Color(UIColor.separator).opacity(0.5)
    }

    // MARK: - Shadows

    enum Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: 2.0, x: 0.0, y: 1.0)
        static let medium = (color: Color.black.opacity(0.15), radius: 8.0, x: 0.0, y: 2.0)
        static let large = (color: Color.black.opacity(0.2), radius: 16.0, x: 0.0, y: 4.0)
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Opacity

    enum Opacity {
        static let disabled: Double = 0.5
        static let subtle: Double = 0.6
        static let medium: Double = 0.8
        static let full: Double = 1.0
    }
}

// MARK: - View Extensions for Design System

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }

    /// Apply material/frosted glass effect
    func materialBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }

    /// Apply standard shadow
    func standardShadow() -> some View {
        let shadow = DesignSystem.Shadow.medium
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Apply standard screen padding
    func screenPadding() -> some View {
        self.padding(DesignSystem.Spacing.screenPadding)
    }

    /// Apply animated scale effect on tap
    func scaleOnTap(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(ScaleButtonStyle(scale: scale))
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primaryLight)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

//
//  DesignTokens.swift
//  SubTrackr
//
//  Apple HIG-compliant design system tokens for consistent UI across the app
//

import SwiftUI

/// Central design system for SubTrackr app
/// Follows Apple's Human Interface Guidelines for iOS
enum DesignSystem {

    // MARK: - Spacing

    /// Standard spacing scale following Apple's 4pt grid system
    enum Spacing {
        /// 2pt - Minimal spacing for tight elements
        static let xxs: CGFloat = 2

        /// 4pt - Extra small spacing for tight layouts
        static let xs: CGFloat = 4

        /// 8pt - Small spacing for compact elements
        static let sm: CGFloat = 8

        /// 12pt - Medium spacing for related elements
        static let md: CGFloat = 12

        /// 16pt - Standard spacing (iOS default)
        static let lg: CGFloat = 16

        /// 20pt - Large spacing for section separation
        static let xl: CGFloat = 20

        /// 24pt - Extra large spacing
        static let xxl: CGFloat = 24

        /// 32pt - Huge spacing for major sections
        static let xxxl: CGFloat = 32

        /// 48pt - Extra huge spacing for hero sections
        static let xxxxl: CGFloat = 48

        /// Standard padding for screen edges (iOS default)
        static let screenPadding: CGFloat = 20

        /// Standard card/list item padding
        static let cardPadding: CGFloat = 16

        /// Horizontal list item padding
        static let listItemPadding: CGFloat = 16

        /// Grid spacing for calendar and grids
        static let gridSpacing: CGFloat = 8

        /// Section header spacing
        static let sectionSpacing: CGFloat = 32
    }

    // MARK: - Corner Radius

    /// Corner radius scale following iOS design patterns
    enum CornerRadius {
        /// 4pt - Extra small radius for tags
        static let xs: CGFloat = 4

        /// 8pt - Small radius for buttons and chips
        static let sm: CGFloat = 8

        /// 10pt - iOS standard button radius
        static let button: CGFloat = 10

        /// 12pt - Medium radius for cards
        static let md: CGFloat = 12

        /// 14pt - iOS standard card radius
        static let card: CGFloat = 14

        /// 16pt - Large radius for prominent cards
        static let lg: CGFloat = 16

        /// 20pt - Extra large radius for sheets
        static let xl: CGFloat = 20

        /// 24pt - Huge radius for special elements
        static let xxl: CGFloat = 24

        /// 28pt - Hero element radius
        static let hero: CGFloat = 28

        /// Fully rounded (circular)
        static let full: CGFloat = 1000
    }

    // MARK: - Typography

    /// Typography scale using SF Pro and SF Rounded
    enum Typography {
        // Large Titles - For navigation bars and hero sections
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let largeTitleRounded = Font.system(.largeTitle, design: .rounded).weight(.bold)

        // Display - Extra large headings
        static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 34, weight: .bold, design: .rounded)

        // Title - Section headers (iOS native sizes)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)

        // Headline - Important text
        static let headline = Font.headline
        static let headlineEmphasized = Font.headline.weight(.bold)

        // Body - Standard text (supports Dynamic Type)
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)

        // Callout - Secondary text
        static let callout = Font.callout
        static let calloutEmphasized = Font.callout.weight(.semibold)

        // Subheadline - Tertiary text
        static let subheadline = Font.subheadline
        static let subheadlineEmphasized = Font.subheadline.weight(.semibold)

        // Footnote - Small text
        static let footnote = Font.footnote
        static let footnoteEmphasized = Font.footnote.weight(.semibold)

        // Caption - Tiny text
        static let caption1 = Font.caption
        static let caption2 = Font.caption2

        // Monospaced - For numbers and data
        static let monospacedBody = Font.body.monospaced()
        static let monospacedTitle = Font.title2.monospaced().weight(.semibold)
        static let monospacedLarge = Font.system(size: 28, weight: .bold, design: .monospaced)

        // Rounded - For friendly, approachable text
        static let roundedTitle = Font.system(.title, design: .rounded).weight(.bold)
        static let roundedHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    }

    // MARK: - Colors

    /// Semantic color system supporting light/dark modes
    enum Colors {
        // MARK: Accent & Primary
        /// App accent color - adapts to user's tint preference
        static let accent = Color.accentColor

        // Primary brand color with semantic variations
        static let primary = Color.blue
        static let primarySubtle = Color.blue.opacity(0.15)
        static let primaryMuted = Color.blue.opacity(0.6)

        // MARK: Semantic Colors
        static let success = Color.green
        static let successSubtle = Color.green.opacity(0.15)

        static let warning = Color.orange
        static let warningSubtle = Color.orange.opacity(0.15)

        static let error = Color.red
        static let errorSubtle = Color.red.opacity(0.15)

        static let info = Color.blue
        static let infoSubtle = Color.blue.opacity(0.15)

        // MARK: Background Hierarchy
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        static let groupedBackground = Color(UIColor.systemGroupedBackground)
        static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
        static let tertiaryGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)

        // MARK: Text Hierarchy
        static let label = Color(UIColor.label)
        static let secondaryLabel = Color(UIColor.secondaryLabel)
        static let tertiaryLabel = Color(UIColor.tertiaryLabel)
        static let quaternaryLabel = Color(UIColor.quaternaryLabel)
        static let placeholderText = Color(UIColor.placeholderText)

        // MARK: Category Colors (Vibrant & Adaptive)
        static let streaming = Color(red: 1.0, green: 0.27, blue: 0.23)      // Netflix red
        static let software = Color(red: 0.0, green: 0.48, blue: 1.0)         // iOS blue
        static let fitness = Color(red: 0.2, green: 0.78, blue: 0.35)         // Health green
        static let gaming = Color(red: 0.69, green: 0.32, blue: 0.87)         // Game purple
        static let utilities = Color(red: 1.0, green: 0.58, blue: 0.0)        // Utility orange
        static let news = Color(UIColor.systemGray)
        static let music = Color(red: 1.0, green: 0.18, blue: 0.33)           // Music pink
        static let productivity = Color(red: 0.19, green: 0.82, blue: 0.85)   // Productivity teal
        static let other = Color(red: 0.64, green: 0.52, blue: 0.38)          // Warm brown

        // Category subtle backgrounds
        static func categorySubtle(_ color: Color) -> Color {
            color.opacity(0.12)
        }

        // MARK: UI Elements
        static let separator = Color(UIColor.separator)
        static let opaqueSeparator = Color(UIColor.opaqueSeparator)
        static let link = Color(UIColor.link)

        // Fill colors for controls
        static let fill = Color(UIColor.systemFill)
        static let secondaryFill = Color(UIColor.secondarySystemFill)
        static let tertiaryFill = Color(UIColor.tertiarySystemFill)
        static let quaternaryFill = Color(UIColor.quaternarySystemFill)

        // MARK: Overlays & Effects
        static let overlay = Color.black.opacity(0.3)
        static let overlayLight = Color.black.opacity(0.15)
        static let overlayHeavy = Color.black.opacity(0.5)

        // Card overlays for layering
        static let cardOverlaySubtle = Color(UIColor.label).opacity(0.03)
        static let cardOverlay = Color(UIColor.label).opacity(0.06)
    }

    // MARK: - Elevation & Shadows

    /// Shadow system for depth and hierarchy
    enum Shadow {
        // iOS-style soft shadows
        static let subtle = (color: Color.black.opacity(0.06), radius: 3.0, x: 0.0, y: 1.0)
        static let small = (color: Color.black.opacity(0.08), radius: 6.0, x: 0.0, y: 2.0)
        static let medium = (color: Color.black.opacity(0.12), radius: 10.0, x: 0.0, y: 4.0)
        static let large = (color: Color.black.opacity(0.16), radius: 20.0, x: 0.0, y: 8.0)
        static let extraLarge = (color: Color.black.opacity(0.20), radius: 30.0, x: 0.0, y: 12.0)

        // Colored shadows for accent elements
        static func accent(opacity: Double = 0.3) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: Colors.primary.opacity(opacity), radius: 12.0, x: 0.0, y: 6.0)
        }
    }

    // MARK: - Elevation Levels

    /// Material elevation following iOS design patterns
    enum Elevation {
        static let none: Material = .regular
        static let low: Material = .thin
        static let medium: Material = .regular
        static let high: Material = .thick
        static let ultraHigh: Material = .ultraThick
    }

    // MARK: - Animation

    /// Animation presets following iOS motion principles
    enum Animation {
        // Standard timing curves
        static let instant = SwiftUI.Animation.linear(duration: 0.1)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.45)
        static let slower = SwiftUI.Animation.easeInOut(duration: 0.6)

        // Spring animations (iOS default feel)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0)
        static let springSnappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0)
        static let springSmooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0)

        // Interactive springs for gestures
        static let interactive = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)

        // Special effects
        static let gentle = SwiftUI.Animation.easeOut(duration: 0.4)
        static let emphasized = SwiftUI.Animation.easeOut(duration: 0.5)
    }

    // MARK: - Icon Sizes

    /// SF Symbol size scale
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 14
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 28
        static let xxxl: CGFloat = 32
        static let hero: CGFloat = 44
        static let giant: CGFloat = 64
    }

    // MARK: - Opacity

    /// Opacity scale for UI states
    enum Opacity {
        static let hidden: Double = 0.0
        static let disabled: Double = 0.4
        static let subtle: Double = 0.6
        static let medium: Double = 0.8
        static let full: Double = 1.0
    }

    // MARK: - Haptics

    /// Haptic feedback system for tactile responses
    enum Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        static func heavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        }

        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        static func warning() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }

        static func error() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    // MARK: - Layout Constants

    /// Common layout constants
    enum Layout {
        static let minTapTarget: CGFloat = 44  // iOS minimum tap target
        static let maxContentWidth: CGFloat = 700  // Max width for large screens
        static let listRowHeight: CGFloat = 60  // Standard list row
        static let navigationBarHeight: CGFloat = 44
        static let tabBarHeight: CGFloat = 49
        static let toolbarHeight: CGFloat = 44
    }
}

// MARK: - View Extensions for Design System

extension View {
    // MARK: Card Styles

    /// Apply iOS-style card with subtle background
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }

    /// Apply prominent card style with shadow
    func prominentCardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
            .softShadow()
    }

    /// Apply material/frosted glass effect
    func materialBackground(_ material: Material = .ultraThinMaterial) -> some View {
        self
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
    }

    // MARK: Shadows

    /// Apply soft iOS-style shadow
    func softShadow() -> some View {
        let shadow = DesignSystem.Shadow.small
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
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

    /// Apply prominent shadow for floating elements
    func prominentShadow() -> some View {
        let shadow = DesignSystem.Shadow.large
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    // MARK: Padding & Spacing

    /// Apply standard screen padding (iOS safe area aware)
    func screenPadding() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }

    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.bottom, DesignSystem.Spacing.sectionSpacing)
    }

    // MARK: Interactive Effects

    /// Apply animated scale effect on tap with haptic feedback
    func interactiveScale(scale: CGFloat = 0.96, haptic: Bool = false) -> some View {
        self.buttonStyle(InteractiveScaleButtonStyle(scale: scale, haptic: haptic))
    }

    /// Apply bounce effect for important actions
    func bounceEffect() -> some View {
        self.buttonStyle(BounceButtonStyle())
    }

    // MARK: Shapes & Clipping

    /// Apply continuous corner radius (iOS style)
    func continuousCornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Apply circular clipping
    func circular() -> some View {
        self.clipShape(Circle())
    }

    // MARK: Conditional Modifiers

    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Button Styles

/// Subtle scale animation for interactive elements
struct InteractiveScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && haptic {
                    DesignSystem.Haptics.light()
                }
            }
    }
}

/// Bouncy spring animation for prominent actions
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(DesignSystem.Animation.springBouncy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    DesignSystem.Haptics.medium()
                }
            }
    }
}

/// Primary button style - filled with accent color
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.minTapTarget)
            .background(isDestructive ? DesignSystem.Colors.error : DesignSystem.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    DesignSystem.Haptics.light()
                }
            }
    }
}

/// Secondary button style - subtle background
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(DesignSystem.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.minTapTarget)
            .background(DesignSystem.Colors.primarySubtle)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    DesignSystem.Haptics.light()
                }
            }
    }
}

/// Tertiary button style - minimal with tint color
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.accent)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Pill-shaped button with icon support
struct PillButtonStyle: ButtonStyle {
    var color: Color = DesignSystem.Colors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    DesignSystem.Haptics.light()
                }
            }
    }
}

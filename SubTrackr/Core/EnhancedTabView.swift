import SwiftUI

/// Enhanced TabView with smooth page transitions and animations
struct EnhancedTabView: View {
    @State private var selectedTab: Tab = .calendar
    @State private var previousTab: Tab = .calendar
    @Namespace private var animation

    enum Tab: Int, CaseIterable {
        case calendar = 0
        case overview = 1
        case search = 2
        case settings = 3

        var title: String {
            switch self {
            case .calendar: return "Calendar"
            case .overview: return "Overview"
            case .search: return "Search"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .overview: return "chart.pie.fill"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
            }
        }

        var iconFilled: String {
            switch self {
            case .calendar: return "calendar"
            case .overview: return "chart.pie.fill"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views with transitions
            ZStack {
                CalendarView()
                    .opacity(selectedTab == .calendar ? 1 : 0)
                    .offset(x: selectedTab == .calendar ? 0 : offsetForTab(.calendar))
                    .zIndex(selectedTab == .calendar ? 1 : 0)

                MonthlyOverviewView()
                    .opacity(selectedTab == .overview ? 1 : 0)
                    .offset(x: selectedTab == .overview ? 0 : offsetForTab(.overview))
                    .zIndex(selectedTab == .overview ? 1 : 0)

                SearchView()
                    .opacity(selectedTab == .search ? 1 : 0)
                    .offset(x: selectedTab == .search ? 0 : offsetForTab(.search))
                    .zIndex(selectedTab == .search ? 1 : 0)

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .offset(x: selectedTab == .settings ? 0 : offsetForTab(.settings))
                    .zIndex(selectedTab == .settings ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, namespace: animation)
                .ignoresSafeArea(.keyboard)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            previousTab = oldValue
            DesignSystem.Haptics.selection()
        }
    }

    private func offsetForTab(_ tab: Tab) -> CGFloat {
        let direction = tab.rawValue - selectedTab.rawValue
        return CGFloat(direction) * 50
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: EnhancedTabView.Tab
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EnhancedTabView.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .strokeBorder(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let tab: EnhancedTabView.Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            DesignSystem.Haptics.light()
            action()
        }) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .fill(DesignSystem.Colors.primarySubtle)
                            .matchedGeometryEffect(id: "tab_background", in: namespace)
                            .frame(width: 60, height: 36)
                    }

                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryLabel)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 60, height: 36)
                }

                Text(tab.title)
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(DesignSystem.Animation.springSnappy) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    EnhancedTabView()
}

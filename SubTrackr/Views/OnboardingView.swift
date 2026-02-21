import SwiftUI
import CloudKit

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    @State private var showingAddSubscription = false
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    
    private let pages = [
        OnboardingPage(
            icon: "calendar.badge.plus",
            title: "Track Your Subscriptions",
            description: "Keep track of all your recurring subscriptions in one beautiful calendar view.",
            color: .blue
        ),
        OnboardingPage(
            icon: "chart.pie.fill",
            title: "Visualize Your Spending",
            description: "See exactly where your money goes with detailed charts and monthly overviews.",
            color: .green
        ),
        OnboardingPage(
            icon: "magnifyingglass",
            title: "Search & Organize",
            description: "Quickly find subscriptions and organize them by categories for better management.",
            color: .purple
        ),
        OnboardingPage(
            icon: "icloud.fill",
            title: "Sync Across Devices",
            description: "Your data syncs automatically across all your Apple devices with iCloud.",
            color: .orange
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Enable Permissions",
            description: "Allow notifications for renewal reminders and iCloud sync for your data.",
            color: .blue
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            bottomSection
        }
        .background(
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.1),
                    pages[currentPage].color.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.5), value: currentPage)
        .sheet(isPresented: $showingAddSubscription) {
            EditSubscriptionView(subscription: nil) { subscription in
                CloudKitService.shared.saveSubscription(subscription)
                isFirstLaunch = false
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    isFirstLaunch = false
                }
                .foregroundColor(.secondary)
                .padding()
            }
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageIndicator
            
            if currentPage < pages.count - 1 {
                continueButton
            } else {
                getStartedButton
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 50)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var continueButton: some View {
        Button {
            withAnimation(.spring()) {
                currentPage += 1
            }
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(pages[currentPage].color)
                )
        }
    }
    
    private var notificationsEnabled: Bool {
        permissionsManager.notificationPermissionStatus == .authorized
    }

    private var getStartedButton: some View {
        VStack(spacing: 16) {
            if currentPage == pages.count - 1 {
                // Permissions page
                VStack(spacing: 12) {
                    // Notification permission button with state
                    Button {
                        if !notificationsEnabled {
                            Task {
                                await permissionsManager.requestNotificationPermissions()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if notificationsEnabled {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            Text(notificationsEnabled ? "Notifications Enabled" : "Allow Notifications")
                                .font(.headline)
                        }
                        .foregroundColor(notificationsEnabled ? pages[currentPage].color : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(notificationsEnabled ? pages[currentPage].color.opacity(0.15) : pages[currentPage].color)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(notificationsEnabled ? pages[currentPage].color : Color.clear, lineWidth: 2)
                        )
                    }
                    .disabled(notificationsEnabled)
                    .animation(.easeInOut(duration: 0.3), value: notificationsEnabled)

                    Button {
                        showingAddSubscription = true
                    } label: {
                        Text("Add Your First Subscription")
                            .font(.subheadline)
                            .foregroundColor(pages[currentPage].color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(pages[currentPage].color, lineWidth: 1)
                            )
                    }
                }
            } else {
                Button {
                    showingAddSubscription = true
                } label: {
                    Text("Add Your First Subscription")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(pages[currentPage].color)
                        )
                }
            }

            Button("I'll Do This Later") {
                isFirstLaunch = false
            }
            .foregroundColor(.secondary)
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(page.color)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
}
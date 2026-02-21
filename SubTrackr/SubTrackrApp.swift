//
//  SubTrackrApp.swift
//  SubTrackr
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import SwiftUI
import CloudKit

@main
struct SubTrackrApp: App {
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @State private var showSplashScreen = true

    // Shared ViewModel for entire app
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()

    init() {
        // Initialize CloudKit service
        _ = CloudKitService.shared

        // Configure appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplashScreen {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplashScreen = false
                        }
                    }
                } else if isFirstLaunch {
                    OnboardingView(isFirstLaunch: $isFirstLaunch)
                } else {
                    ContentView()
                }
            }
            .environmentObject(subscriptionViewModel)
            .preferredColorScheme(.none)
        }
    }
    
    private func setupAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

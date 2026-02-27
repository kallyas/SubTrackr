//
//  ContentView.swift
//  SubTrackr
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @StateObject private var viewModel = SubscriptionViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(0)
            
            MonthlyOverviewView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Overview")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
            
            ShareSubscriptionView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Share")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(.blue)
        .onAppear {
            // Request permissions on first launch
            Task {
                if permissionsManager.notificationPermissionStatus == .notDetermined {
                    _ = await permissionsManager.requestNotificationPermissions()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

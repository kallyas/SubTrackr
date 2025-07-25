//
//  WidgetDataManager.swift
//  SubTrackr
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Foundation
import SwiftUI
import WidgetKit

struct WidgetSubscription: Codable, Identifiable {
    let id: String
    let name: String
    let cost: Double
    let currencyCode: String
    let billingCycle: String
    let nextBillingDate: Date
    let category: String
    let iconName: String
    let isActive: Bool
    
    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: cost)) ?? "\(cost)"
    }
    
    var monthlyCost: Double {
        switch billingCycle {
        case "Weekly": return cost * 4.33
        case "Monthly": return cost
        case "Quarterly": return cost / 3.0
        case "Semi-Annual": return cost / 6.0
        case "Annual": return cost / 12.0
        default: return cost
        }
    }
    
    var categoryColor: Color {
        switch category {
        case "Streaming": return .red
        case "Software": return .blue
        case "Fitness": return .green
        case "Gaming": return .purple
        case "Utilities": return .orange
        case "News": return .gray
        case "Music": return .pink
        case "Productivity": return .teal
        default: return .brown
        }
    }
}

struct WidgetData: Codable {
    let subscriptions: [WidgetSubscription]
    let monthlyTotal: Double
    let userCurrencyCode: String
    let lastUpdated: Date
    
    var upcomingRenewals: [WidgetSubscription] {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= today &&
            subscription.nextBillingDate <= oneWeekFromNow
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    var formattedMonthlyTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userCurrencyCode
        return formatter.string(from: NSNumber(value: monthlyTotal)) ?? "\(monthlyTotal)"
    }
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupId = "group.com.iden.SubTrackr"
    private let dataKey = "widgetData"
    
    private init() {}
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    func saveWidgetData(_ data: WidgetData) {
        guard let encoder = try? JSONEncoder().encode(data),
              let userDefaults = userDefaults else { return }
        
        userDefaults.set(encoder, forKey: dataKey)
        userDefaults.synchronize()
    }
    
    func loadWidgetData() -> WidgetData? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return getSampleData()
        }
        
        return widgetData
    }
    
    func getSampleData() -> WidgetData {
        let sampleSubscriptions = [
            WidgetSubscription(
                id: "1",
                name: "Netflix",
                cost: 15.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                category: "Streaming",
                iconName: "tv.fill",
                isActive: true
            ),
            WidgetSubscription(
                id: "2",
                name: "Spotify",
                cost: 9.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                category: "Music",
                iconName: "music.note",
                isActive: true
            ),
            WidgetSubscription(
                id: "3",
                name: "Adobe Creative",
                cost: 52.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                category: "Software",
                iconName: "briefcase.fill",
                isActive: true
            )
        ]
        
        return WidgetData(
            subscriptions: sampleSubscriptions,
            monthlyTotal: 78.97,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
    }
}
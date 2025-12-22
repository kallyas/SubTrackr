//
//  WidgetDataTypes.swift
//  WidgetShared
//
//  Shared data structures for SubTrackr app and widget
//

import Foundation
import SwiftUI

/// Represents a subscription in a simplified format for widget display
public struct WidgetSubscription: Codable, Identifiable {
    public let id: String
    public let name: String
    public let cost: Double
    public let currencyCode: String
    public let billingCycle: String
    public let nextBillingDate: Date
    public let category: String
    public let iconName: String
    public let isActive: Bool

    public init(
        id: String,
        name: String,
        cost: Double,
        currencyCode: String,
        billingCycle: String,
        nextBillingDate: Date,
        category: String,
        iconName: String,
        isActive: Bool
    ) {
        self.id = id
        self.name = name
        self.cost = cost
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
        self.category = category
        self.iconName = iconName
        self.isActive = isActive
    }

    /// Formatted cost string with currency symbol
    public var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: cost)) ?? "\(cost)"
    }

    /// Color associated with the subscription category
    public var categoryColor: Color {
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

/// Container for all widget data including subscriptions and monthly totals
public struct WidgetData: Codable {
    public let subscriptions: [WidgetSubscription]
    public let monthlyTotal: Double
    public let userCurrencyCode: String
    public let lastUpdated: Date

    public init(
        subscriptions: [WidgetSubscription],
        monthlyTotal: Double,
        userCurrencyCode: String,
        lastUpdated: Date
    ) {
        self.subscriptions = subscriptions
        self.monthlyTotal = monthlyTotal
        self.userCurrencyCode = userCurrencyCode
        self.lastUpdated = lastUpdated
    }

    /// Returns subscriptions that will renew in the next 7 days
    public var upcomingRenewals: [WidgetSubscription] {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= today &&
            subscription.nextBillingDate <= oneWeekFromNow
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    /// Formatted monthly total with currency symbol
    public var formattedMonthlyTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userCurrencyCode
        return formatter.string(from: NSNumber(value: monthlyTotal)) ?? "\(monthlyTotal)"
    }

    /// Empty widget data for when no subscriptions exist
    public static var empty: WidgetData {
        WidgetData(
            subscriptions: [],
            monthlyTotal: 0,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
    }

    /// Preview data for development and SwiftUI previews
    public static var previewData: WidgetData {
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

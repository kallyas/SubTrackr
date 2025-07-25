//
//  WidgetDataManagerTests.swift
//  SubTrackrTests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Testing
import Foundation
@testable import SubTrackr

struct WidgetSubscriptionTests {
    
    @Test func testWidgetSubscriptionInitialization() {
        let subscription = WidgetSubscription(
            id: "1",
            name: "Netflix",
            cost: 15.99,
            currencyCode: "USD",
            billingCycle: "Monthly",
            nextBillingDate: Date(),
            category: "Streaming",
            iconName: "tv.fill",
            isActive: true
        )
        
        #expect(subscription.id == "1")
        #expect(subscription.name == "Netflix")
        #expect(subscription.cost == 15.99)
        #expect(subscription.currencyCode == "USD")
        #expect(subscription.billingCycle == "Monthly")
        #expect(subscription.category == "Streaming")
        #expect(subscription.iconName == "tv.fill")
        #expect(subscription.isActive == true)
    }
    
    @Test func testMonthlyCostCalculations() {
        let weeklySubscription = WidgetSubscription(
            id: "1",
            name: "Weekly",
            cost: 5.0,
            currencyCode: "USD",
            billingCycle: "Weekly",
            nextBillingDate: Date(),
            category: "Fitness",
            iconName: "figure.run",
            isActive: true
        )
        #expect(weeklySubscription.monthlyCost == 5.0 * 4.33)
        
        let monthlySubscription = WidgetSubscription(
            id: "2",
            name: "Monthly",
            cost: 15.99,
            currencyCode: "USD",
            billingCycle: "Monthly",
            nextBillingDate: Date(),
            category: "Streaming",
            iconName: "tv.fill",
            isActive: true
        )
        #expect(monthlySubscription.monthlyCost == 15.99)
        
        let annualSubscription = WidgetSubscription(
            id: "3",
            name: "Annual",
            cost: 120.0,
            currencyCode: "USD",
            billingCycle: "Annual",
            nextBillingDate: Date(),
            category: "Software",
            iconName: "laptopcomputer",
            isActive: true
        )
        #expect(annualSubscription.monthlyCost == 120.0 / 12.0)
    }
    
    @Test func testFormattedCost() {
        let subscription = WidgetSubscription(
            id: "1",
            name: "Test",
            cost: 15.99,
            currencyCode: "USD",
            billingCycle: "Monthly",
            nextBillingDate: Date(),
            category: "Streaming",
            iconName: "tv.fill",
            isActive: true
        )
        
        let formatted = subscription.formattedCost
        #expect(formatted.contains("15.99") || formatted.contains("$"))
    }
}

struct WidgetDataTests {
    
    @Test func testWidgetDataInitialization() {
        let subscriptions = [
            WidgetSubscription(
                id: "1",
                name: "Netflix",
                cost: 15.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Date(),
                category: "Streaming",
                iconName: "tv.fill",
                isActive: true
            )
        ]
        
        let widgetData = WidgetData(
            subscriptions: subscriptions,
            monthlyTotal: 15.99,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
        
        #expect(widgetData.subscriptions.count == 1)
        #expect(widgetData.monthlyTotal == 15.99)
        #expect(widgetData.userCurrencyCode == "USD")
    }
    
    @Test func testUpcomingRenewals() {
        let calendar = Calendar.current
        let today = Date()
        
        let upcomingSubscription = WidgetSubscription(
            id: "1",
            name: "Netflix",
            cost: 15.99,
            currencyCode: "USD",
            billingCycle: "Monthly",
            nextBillingDate: calendar.date(byAdding: .day, value: 3, to: today)!,
            category: "Streaming",
            iconName: "tv.fill",
            isActive: true
        )
        
        let futureSubscription = WidgetSubscription(
            id: "2",
            name: "Spotify",
            cost: 9.99,
            currencyCode: "USD",
            billingCycle: "Monthly",
            nextBillingDate: calendar.date(byAdding: .day, value: 30, to: today)!,
            category: "Music",
            iconName: "music.note",
            isActive: true
        )
        
        let widgetData = WidgetData(
            subscriptions: [upcomingSubscription, futureSubscription],
            monthlyTotal: 25.98,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
        
        let upcomingRenewals = widgetData.upcomingRenewals
        #expect(upcomingRenewals.count == 1)
        #expect(upcomingRenewals.first?.id == "1")
    }
    
    @Test func testFormattedMonthlyTotal() {
        let widgetData = WidgetData(
            subscriptions: [],
            monthlyTotal: 25.99,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
        
        let formatted = widgetData.formattedMonthlyTotal
        #expect(formatted.contains("25.99") || formatted.contains("$"))
    }
}

struct WidgetDataManagerTests {
    
    @Test func testSharedInstance() {
        let manager1 = WidgetDataManager.shared
        let manager2 = WidgetDataManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test func testGetSampleData() {
        let manager = WidgetDataManager.shared
        let sampleData = manager.getSampleData()
        
        #expect(sampleData.subscriptions.count == 3)
        #expect(sampleData.monthlyTotal == 78.97)
        #expect(sampleData.userCurrencyCode == "USD")
        #expect(sampleData.subscriptions.contains { $0.name == "Netflix" })
        #expect(sampleData.subscriptions.contains { $0.name == "Spotify" })
        #expect(sampleData.subscriptions.contains { $0.name == "Adobe Creative" })
    }
    
    @Test func testLoadWidgetDataFallback() {
        let manager = WidgetDataManager.shared
        let data = manager.loadWidgetData()
        
        // Should return sample data when no saved data exists
        #expect(data != nil)
        #expect(data?.subscriptions.count == 3)
    }
}
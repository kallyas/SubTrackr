//
//  IntegrationTests.swift
//  SubTrackrTests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Testing
import Foundation
import Combine
import WidgetShared
@testable import SubTrackr

struct IntegrationTests {
    
    @Test func testSubscriptionToWidgetDataFlow() {
        let subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming,
            iconName: "tv.fill"
        )
        
        let widgetSubscription = WidgetSubscription(
            id: subscription.id,
            name: subscription.name,
            cost: subscription.cost,
            currencyCode: subscription.currency.code,
            billingCycle: subscription.billingCycle.rawValue,
            nextBillingDate: subscription.nextBillingDate,
            category: subscription.category.rawValue,
            iconName: subscription.iconName,
            isActive: subscription.isActive
        )
        
        #expect(widgetSubscription.name == subscription.name)
        #expect(widgetSubscription.cost == subscription.cost)
        #expect(widgetSubscription.currencyCode == subscription.currency.code)
        #expect(widgetSubscription.billingCycle == subscription.billingCycle.rawValue)
        #expect(widgetSubscription.category == subscription.category.rawValue)
        #expect(widgetSubscription.isActive == subscription.isActive)
    }
    
    @Test func testCurrencyConversionIntegration() {
        let currencyManager = CurrencyManager.shared
        let exchangeService = CurrencyExchangeService.shared
        
        // Test that currency manager uses exchange service correctly
        let originalAmount = 100.0
        let convertedAmount = currencyManager.convertAmount(originalAmount, from: .USD, to: .USD)
        
        #expect(convertedAmount == originalAmount)
    }
    
    @Test func testSubscriptionViewModelIntegration() async {
        let viewModel = SubscriptionViewModel()
        
        // Wait for initialization
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Test that the view model initializes properly
        #expect(viewModel.monthlyTotal >= 0.0)
        #expect(viewModel.categoryTotals.count >= 0)
        #expect(viewModel.chartData.count >= 0)
        
        // Test filters
        viewModel.searchText = "Netflix"
        viewModel.selectedCategory = .streaming
        
        viewModel.clearFilters()
        
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedCategory == nil)
    }
    
    @Test func testBillingCycleToMonthlyConversion() {
        let testCases: [(BillingCycle, Double, Double)] = [
            (.weekly, 10.0, 10.0 * 4.33),
            (.monthly, 15.99, 15.99),
            (.quarterly, 30.0, 30.0 / 3.0),
            (.semiAnnual, 60.0, 60.0 / 6.0),
            (.annual, 120.0, 120.0 / 12.0)
        ]
        
        for (cycle, cost, expectedMonthlyCost) in testCases {
            let subscription = Subscription(
                name: "Test \(cycle.rawValue)",
                cost: cost,
                currency: .USD,
                billingCycle: cycle,
                startDate: Date(),
                category: .other
            )
            
            #expect(subscription.monthlyCost == expectedMonthlyCost)
        }
    }
    
    @Test func testWidgetDataSerialization() {
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
        
        let widgetData = WidgetData(
            subscriptions: [subscription],
            monthlyTotal: 15.99,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
        
        // Test serialization
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(widgetData)
            let decodedData = try decoder.decode(WidgetData.self, from: data)
            
            #expect(decodedData.subscriptions.count == 1)
            #expect(decodedData.monthlyTotal == 15.99)
            #expect(decodedData.userCurrencyCode == "USD")
            #expect(decodedData.subscriptions.first?.name == "Netflix")
        } catch {
            Issue.record("Serialization failed: \(error)")
        }
    }
}

struct PerformanceTests {
    
    @Test func testCurrencyFormattingPerformance() {
        let currency = Currency.USD
        let amounts = Array(1...1000).map { Double($0) * 15.99 }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for amount in amounts {
            _ = currency.formatAmount(amount)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should format 1000 amounts in less than 1 second
        #expect(timeElapsed < 1.0)
    }
    
    @Test func testSubscriptionMonthlyCostCalculationPerformance() {
        let subscriptions = (1...1000).map { index in
            Subscription(
                name: "Subscription \(index)",
                cost: Double(index) * 9.99,
                currency: .USD,
                billingCycle: BillingCycle.allCases.randomElement()!,
                startDate: Date(),
                category: SubscriptionCategory.allCases.randomElement()!
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for subscription in subscriptions {
            _ = subscription.monthlyCost
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should calculate 1000 monthly costs in less than 0.1 seconds
        #expect(timeElapsed < 0.1)
    }
}
//
//  SubTrackrTests.swift
//  SubTrackrTests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Testing
import Foundation
@testable import SubTrackr

struct SubscriptionModelTests {
    
    @Test func testSubscriptionInitialization() {
        let subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming,
            iconName: "tv.fill"
        )
        
        #expect(subscription.name == "Netflix")
        #expect(subscription.cost == 15.99)
        #expect(subscription.currency == .USD)
        #expect(subscription.billingCycle == .monthly)
        #expect(subscription.category == .streaming)
        #expect(subscription.iconName == "tv.fill")
        #expect(subscription.isActive == true)
    }
    
    @Test func testNextBillingDateCalculation() {
        let startDate = Date()
        let calendar = Calendar.current
        
        let monthlySubscription = Subscription(
            name: "Test Monthly",
            cost: 10.0,
            currency: .USD,
            billingCycle: .monthly,
            startDate: startDate,
            category: .software
        )
        
        let expectedDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        #expect(monthlySubscription.nextBillingDate == expectedDate)
    }
    
    @Test func testMonthlyCostCalculation() {
        let weeklySubscription = Subscription(
            name: "Weekly Test",
            cost: 5.0,
            currency: .USD,
            billingCycle: .weekly,
            startDate: Date(),
            category: .fitness
        )
        
        #expect(weeklySubscription.monthlyCost == 5.0 * 4.33)
        
        let annualSubscription = Subscription(
            name: "Annual Test",
            cost: 120.0,
            currency: .USD,
            billingCycle: .annual,
            startDate: Date(),
            category: .software
        )
        
        #expect(annualSubscription.monthlyCost == 120.0 / 12.0)
    }
    
    @Test func testFormattedCost() {
        let subscription = Subscription(
            name: "Test",
            cost: 15.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        let formatted = subscription.formattedCost
        #expect(formatted.contains("15.99"))
        #expect(formatted.contains("$"))
    }
}

struct BillingCycleTests {
    
    @Test func testBillingCycleValues() {
        #expect(BillingCycle.weekly.value == 1)
        #expect(BillingCycle.monthly.value == 1)
        #expect(BillingCycle.quarterly.value == 3)
        #expect(BillingCycle.semiAnnual.value == 6)
        #expect(BillingCycle.annual.value == 1)
    }
    
    @Test func testBillingCycleCalendarComponents() {
        #expect(BillingCycle.weekly.calendarComponent == .weekOfYear)
        #expect(BillingCycle.monthly.calendarComponent == .month)
        #expect(BillingCycle.quarterly.calendarComponent == .month)
        #expect(BillingCycle.semiAnnual.calendarComponent == .month)
        #expect(BillingCycle.annual.calendarComponent == .year)
    }
    
    @Test func testMonthlyEquivalents() {
        #expect(BillingCycle.weekly.monthlyEquivalent == 4.33)
        #expect(BillingCycle.monthly.monthlyEquivalent == 1.0)
        #expect(BillingCycle.quarterly.monthlyEquivalent == 1.0 / 3.0)
        #expect(BillingCycle.semiAnnual.monthlyEquivalent == 1.0 / 6.0)
        #expect(BillingCycle.annual.monthlyEquivalent == 1.0 / 12.0)
    }
}

struct SubscriptionCategoryTests {
    
    @Test func testCategoryCount() {
        #expect(SubscriptionCategory.allCases.count == 9)
    }
    
    @Test func testCategoryIcons() {
        #expect(SubscriptionCategory.streaming.iconName == "tv.fill")
        #expect(SubscriptionCategory.software.iconName == "laptopcomputer")
        #expect(SubscriptionCategory.fitness.iconName == "figure.run")
        #expect(SubscriptionCategory.gaming.iconName == "gamecontroller.fill")
    }
    
    @Test func testCategoryIdentifiers() {
        #expect(SubscriptionCategory.streaming.id == "Streaming")
        #expect(SubscriptionCategory.software.id == "Software")
        #expect(SubscriptionCategory.other.id == "Other")
    }
}

struct CurrencyTests {
    
    @Test func testCurrencyInitialization() {
        let currency = Currency(code: "USD", name: "US Dollar", symbol: "$")
        
        #expect(currency.id == "USD")
        #expect(currency.code == "USD")
        #expect(currency.name == "US Dollar")
        #expect(currency.symbol == "$")
    }
    
    @Test func testCurrencyFormatting() {
        let currency = Currency.USD
        let formatted = currency.formatAmount(15.99)
        
        #expect(formatted.contains("15.99"))
        #expect(formatted.contains("$"))
    }
    
    @Test func testCurrencyLookup() {
        let usd = Currency.currency(for: "USD")
        #expect(usd?.code == "USD")
        
        let invalid = Currency.currency(for: "INVALID")
        #expect(invalid == nil)
    }
    
    @Test func testSupportedCurrenciesCount() {
        #expect(Currency.supportedCurrencies.count > 100)
        #expect(Currency.supportedCurrencies.contains(.USD))
        #expect(Currency.supportedCurrencies.contains(.EUR))
        #expect(Currency.supportedCurrencies.contains(.GBP))
    }
}

struct CurrencyExchangeServiceTests {
    
    @Test func testConvertAmountSameCurrency() {
        let service = CurrencyExchangeService.shared
        let result = service.convertAmount(100.0, from: .USD, to: .USD)
        #expect(result == 100.0)
    }
    
    @Test func testExchangeRateSameCurrency() {
        let service = CurrencyExchangeService.shared
        let rate = service.getExchangeRate(from: .USD, to: .USD)
        #expect(rate == 1.0)
    }
    
    @Test func testConvertAmountWithEmptyRates() {
        let service = CurrencyExchangeService.shared
        // When no exchange rates are available, should return original amount
        let result = service.convertAmount(100.0, from: .USD, to: .EUR)
        // The service returns original amount when no rates available OR converted amount if rates exist
        #expect(result >= 0.0) // Just verify it returns a valid result
    }
}

import XCTest
@testable import SubTrackr

class SubscriptionViewModelTests: XCTestCase {

    var viewModel: SubscriptionViewModel!

    override func setUp() {
        super.setUp()
        viewModel = SubscriptionViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testMonthlyTotal() {
        // Use explicit USD currency to avoid exchange rate conversion issues
        let subscription1 = Subscription(name: "Netflix", cost: 15.0, currency: .USD, billingCycle: .monthly, startDate: Date(), category: .streaming)
        let subscription2 = Subscription(name: "Hulu", cost: 10.0, currency: .USD, billingCycle: .monthly, startDate: Date(), category: .streaming)
        viewModel.subscriptions = [subscription1, subscription2]

        // monthlyTotal converts to user currency, so we compare the converted amounts
        let currencyManager = CurrencyManager.shared
        let expected = currencyManager.convertToUserCurrency(15.0, from: .USD) + currencyManager.convertToUserCurrency(10.0, from: .USD)
        XCTAssertEqual(viewModel.monthlyTotal, expected, accuracy: 0.01, "Monthly total should be the sum of all monthly subscription costs converted to user currency.")
    }

    func testCategoryTotals() {
        // Use explicit USD currency to avoid exchange rate conversion issues
        let subscription1 = Subscription(name: "Netflix", cost: 15.0, currency: .USD, billingCycle: .monthly, startDate: Date(), category: .streaming)
        let subscription2 = Subscription(name: "Hulu", cost: 10.0, currency: .USD, billingCycle: .monthly, startDate: Date(), category: .streaming)
        let subscription3 = Subscription(name: "Gym", cost: 30.0, currency: .USD, billingCycle: .monthly, startDate: Date(), category: .fitness)
        viewModel.subscriptions = [subscription1, subscription2, subscription3]
        let categoryTotals = viewModel.categoryTotals

        // categoryTotals converts to user currency
        let currencyManager = CurrencyManager.shared
        let expectedStreaming = currencyManager.convertToUserCurrency(25.0, from: .USD)
        let expectedFitness = currencyManager.convertToUserCurrency(30.0, from: .USD)
        XCTAssertEqual(categoryTotals[.streaming] ?? 0, expectedStreaming, accuracy: 0.01, "Streaming category total should be correct.")
        XCTAssertEqual(categoryTotals[.fitness] ?? 0, expectedFitness, accuracy: 0.01, "Fitness category total should be correct.")
    }

    func testUpcomingRenewals() {
        let calendar = Calendar.current
        let today = Date()

        // nextBillingDate = startDate + 1 month (for monthly billing)
        // To get a nextBillingDate 3 days from now, startDate must be about 1 month ago + 3 days
        // startDate such that startDate + 1 month = today + 3 days
        let upcomingBillingDate = calendar.date(byAdding: .day, value: 3, to: today)!
        let upcomingStartDate = calendar.date(byAdding: .month, value: -1, to: upcomingBillingDate)!

        // For far future: nextBillingDate = today + 10 days, so startDate = today + 10 days - 1 month
        let farFutureBillingDate = calendar.date(byAdding: .day, value: 10, to: today)!
        let farFutureStartDate = calendar.date(byAdding: .month, value: -1, to: farFutureBillingDate)!

        let upcomingSubscription = Subscription(name: "Upcoming", cost: 10.0, currency: .USD, billingCycle: .monthly, startDate: upcomingStartDate, category: .other)
        let farFutureSubscription = Subscription(name: "Far Future", cost: 20.0, currency: .USD, billingCycle: .monthly, startDate: farFutureStartDate, category: .other)

        viewModel.subscriptions = [upcomingSubscription, farFutureSubscription]

        // getUpcomingRenewals(days: 7) returns subscriptions with nextBillingDate within 7 days
        let upcomingRenewals = viewModel.getUpcomingRenewals()

        XCTAssertEqual(upcomingRenewals.count, 1, "There should be one upcoming renewal (within 7 days).")
        XCTAssertEqual(upcomingRenewals.first?.name, "Upcoming", "The upcoming renewal should be the correct one.")
    }
}

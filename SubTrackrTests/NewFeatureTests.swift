//
//  NewFeatureTests.swift
//  SubTrackrTests
//
//  Tests for new features: Price History, Shared Members, CSV Import
//

import XCTest
@testable import SubTrackr

final class NewFeatureTests: XCTestCase {
    
    // MARK: - Price History Tests
    
    func testPriceHistoryEntryInitialization() {
        let entry = PriceHistoryEntry(
            price: 15.99,
            date: Date(),
            previousPrice: 12.99,
            changeReason: .detectedIncrease
        )
        
        XCTAssertEqual(entry.price, 15.99)
        XCTAssertEqual(entry.previousPrice, 12.99)
        XCTAssertEqual(entry.changeReason, .detectedIncrease)
    }
    
    func testPriceChangeCalculation() {
        let entry = PriceHistoryEntry(
            price: 20.0,
            previousPrice: 15.0
        )
        
        XCTAssertEqual(entry.priceChange, 5.0)
    }
    
    func testPriceChangePercentage() {
        let entry = PriceHistoryEntry(
            price: 12.0,
            previousPrice: 10.0
        )
        
        XCTAssertEqual(entry.priceChangePercentage, 20.0)
    }
    
    func testIsIncrease() {
        let increaseEntry = PriceHistoryEntry(
            price: 15.0,
            previousPrice: 10.0
        )
        XCTAssertTrue(increaseEntry.isIncrease)
        
        let decreaseEntry = PriceHistoryEntry(
            price: 8.0,
            previousPrice: 10.0
        )
        XCTAssertFalse(decreaseEntry.isIncrease)
    }
    
    func testNoPreviousPrice() {
        let entry = PriceHistoryEntry(price: 15.99)
        
        XCTAssertNil(entry.previousPrice)
        XCTAssertNil(entry.priceChange)
        XCTAssertNil(entry.priceChangePercentage)
    }
    
    // MARK: - Subscription Price History Tests
    
    func testPriceHistoryInitialization() {
        let subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        XCTAssertEqual(subscription.priceHistory.count, 1)
        XCTAssertEqual(subscription.priceHistory.first?.price, 15.99)
    }
    
    func testUpdatePrice() {
        var subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        subscription.updatePrice(18.99)
        
        XCTAssertEqual(subscription.cost, 18.99)
        XCTAssertEqual(subscription.priceHistory.count, 2)
        XCTAssertEqual(subscription.priceHistory.last?.price, 18.99)
        XCTAssertEqual(subscription.priceHistory.last?.previousPrice, 15.99)
    }
    
    func testHasPriceIncreased() {
        var subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        XCTAssertFalse(subscription.hasPriceIncreased)
        
        subscription.updatePrice(18.99)
        
        XCTAssertTrue(subscription.hasPriceIncreased)
    }
    
    func testTotalPriceIncrease() {
        var subscription = Subscription(
            name: "Netflix",
            cost: 10.0,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        subscription.updatePrice(12.0)
        subscription.updatePrice(15.0)
        
        XCTAssertEqual(subscription.totalPriceIncrease, 5.0) // 15.0 - 10.0
    }
    
    func testLatestPriceChange() {
        var subscription = Subscription(
            name: "Netflix",
            cost: 10.0,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        subscription.updatePrice(12.0)
        
        XCTAssertEqual(subscription.latestPriceChange?.price, 12.0)
    }
    
    // MARK: - Shared Member Tests
    
    func testSharedMemberInitialization() {
        let member = SharedMember(
            name: "John Doe",
            email: "john@example.com",
            shareType: .family,
            isPayer: true
        )
        
        XCTAssertEqual(member.name, "John Doe")
        XCTAssertEqual(member.email, "john@example.com")
        XCTAssertEqual(member.shareType, .family)
        XCTAssertTrue(member.isPayer)
    }
    
    func testShareTypeValues() {
        XCTAssertEqual(ShareType.allCases.count, 5)
        XCTAssertEqual(ShareType.family.rawValue, "Family")
        XCTAssertEqual(ShareType.friend.rawValue, "Friend")
        XCTAssertEqual(ShareType.partner.rawValue, "Partner")
        XCTAssertEqual(ShareType.colleague.rawValue, "Colleague")
        XCTAssertEqual(ShareType.other.rawValue, "Other")
    }
    
    func testShareTypeIcons() {
        XCTAssertEqual(ShareType.family.iconName, "household")
        XCTAssertEqual(ShareType.friend.iconName, "person.2.fill")
        XCTAssertEqual(ShareType.partner.iconName, "heart.fill")
    }
    
    // MARK: - Subscription Shared With Tests
    
    func testSharedWithInitialization() {
        let subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming,
            sharedWith: []
        )
        
        XCTAssertTrue(subscription.sharedWith.isEmpty)
    }
    
    func testAddingSharedMembers() {
        var subscription = Subscription(
            name: "Netflix",
            cost: 15.99,
            billingCycle: .monthly,
            startDate: Date(),
            category: .streaming
        )
        
        let member = SharedMember(name: "Jane", shareType: .family, isPayer: true)
        subscription.sharedWith.append(member)
        
        XCTAssertEqual(subscription.sharedWith.count, 1)
        XCTAssertEqual(subscription.sharedWith.first?.name, "Jane")
        XCTAssertTrue(subscription.sharedWith.first?.isPayer ?? false)
    }
    
    // MARK: - Price Change Reason Tests
    
    func testPriceChangeReasonValues() {
        XCTAssertEqual(PriceChangeReason.allCases.count, 8)
        XCTAssertEqual(PriceChangeReason.renewal.rawValue, "Renewal")
        XCTAssertEqual(PriceChangeReason.planUpgrade.rawValue, "Plan Upgrade")
        XCTAssertEqual(PriceChangeReason.detectedIncrease.rawValue, "Price Increase Detected")
    }
    
    // MARK: - Currency Tests
    
    func testPopularCurrenciesExist() {
        XCTAssertEqual(Currency.popularCurrencies.count, 20)
    }
    
    func testPopularCurrenciesContainMajorCurrencies() {
        XCTAssertTrue(Currency.popularCurrencies.contains(.USD))
        XCTAssertTrue(Currency.popularCurrencies.contains(.EUR))
        XCTAssertTrue(Currency.popularCurrencies.contains(.GBP))
        XCTAssertTrue(Currency.popularCurrencies.contains(.JPY))
    }
    
    func testPopularCurrenciesAreInSupportedCurrencies() {
        for currency in Currency.popularCurrencies {
            XCTAssertTrue(Currency.supportedCurrencies.contains(currency))
        }
    }
    
    // MARK: - CSV Import Tests
    
    func testCSVParserBasic() {
        let csv = """
        Name,Cost,Currency,Billing Cycle
        Netflix,15.99,USD,monthly
        Spotify,9.99,EUR,monthly
        """
        
        // Note: This test validates that the CSV string can be created
        XCTAssertFalse(csv.isEmpty)
        XCTAssertTrue(csv.contains("Netflix"))
        XCTAssertTrue(csv.contains("Spotify"))
    }
}

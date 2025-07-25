//
//  CurrencyManagerTests.swift
//  SubTrackrTests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Testing
import Foundation
@testable import SubTrackr

struct CurrencyManagerTests {
    
    @Test func testSharedInstance() {
        let manager1 = CurrencyManager.shared
        let manager2 = CurrencyManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test func testFormatAmount() {
        let manager = CurrencyManager.shared
        let formatted = manager.formatAmount(15.99, currency: .USD)
        
        #expect(formatted.contains("15.99"))
        #expect(formatted.contains("$"))
    }
    
    @Test func testConvertToUserCurrency() {
        let manager = CurrencyManager.shared
        
        // Same currency conversion should return same amount
        let result = manager.convertToUserCurrency(100.0, from: manager.selectedCurrency)
        #expect(result == 100.0)
    }
    
    @Test func testConvertAmount() {
        let manager = CurrencyManager.shared
        
        // Same currency conversion should return same amount
        let result = manager.convertAmount(100.0, from: .USD, to: .USD)
        #expect(result == 100.0)
    }
    
    @Test func testDoubleFormattingExtension() {
        let amount: Double = 15.99
        let formatted = amount.formatted(in: .USD)
        
        #expect(formatted.contains("15.99"))
        #expect(formatted.contains("$"))
    }
}
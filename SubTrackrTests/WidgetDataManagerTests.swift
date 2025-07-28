//
//  WidgetDataManagerTests.swift
//  SubTrackrTests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Testing
import Foundation
@testable import SubTrackr

struct WidgetDataManagerTests {
    
    @Test func testSharedInstance() {
        let manager = WidgetDataManager.shared
        #expect(manager != nil)
    }
}

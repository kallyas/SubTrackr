//
//  SubTrackrUITests.swift
//  SubTrackrUITests
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import XCTest

final class SubTrackrUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["IS_RUNNING_UI_TESTS"] = "1"
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAppLaunch() throws {
        app.launch()
        
        // Verify the app launches successfully
        XCTAssertTrue(app.exists, "App should launch successfully")
    }
    
    @MainActor
    func testNavigationFlow() throws {
        app.launch()
        
        // Test basic navigation elements exist
        // Note: These would need to be updated based on actual UI elements
        // This is a basic structure that can be expanded
    }
    
    @MainActor
    func testSubscriptionListView() throws {
        app.launch()
        
        // Verify subscription list elements are accessible
        // This would test the main subscription list view
    }
    
    @MainActor
    func testAddSubscriptionFlow() throws {
        app.launch()
        
        // Test the add subscription flow
        // This would verify the add subscription button and form
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testMemoryPerformance() throws {
        app.launch()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Navigate through key screens to test memory usage
            // This would include navigation to different views
        }
    }
}

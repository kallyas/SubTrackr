//
//  WidgetDataManager.swift
//  SubTrackr
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Foundation
import SwiftUI
import WidgetKit
import WidgetShared

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupId = "group.com.iden.SubTrackr"
    private let dataKey = "widgetData"
    
    private init() {}
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    func saveWidgetData(subscriptions: [Subscription], monthlyTotal: Double, userCurrencyCode: String) {
        let widgetSubscriptions = subscriptions.map { sub in
            WidgetSubscription(
                id: sub.id,
                name: sub.name,
                cost: sub.cost,
                currencyCode: sub.currency.code,
                billingCycle: sub.billingCycle.rawValue,
                nextBillingDate: sub.nextBillingDate,
                category: sub.category.rawValue,
                iconName: sub.iconName,
                isActive: sub.isActive
            )
        }
        
        let widgetData = WidgetData(
            subscriptions: widgetSubscriptions,
            monthlyTotal: monthlyTotal,
            userCurrencyCode: userCurrencyCode,
            lastUpdated: Date()
        )
        
        guard let encodedData = try? JSONEncoder().encode(widgetData), let userDefaults = userDefaults else {
            return
        }
        
        userDefaults.set(encodedData, forKey: dataKey)
        userDefaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func loadWidgetData() -> WidgetData? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        
        return widgetData
    }
    
    func clearWidgetData() {
        userDefaults?.removeObject(forKey: dataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

//
//  SubscriptionLiveActivityAttributes.swift
//  WidgetShared
//

import ActivityKit
import Foundation

public struct SubscriptionLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var nextBillingDate: Date
        public var additionalSubscriptionsCount: Int
        public var relatedSubscriptions: [RelatedSubscription]

        public init(
            nextBillingDate: Date,
            additionalSubscriptionsCount: Int = 0,
            relatedSubscriptions: [RelatedSubscription] = []
        ) {
            self.nextBillingDate = nextBillingDate
            self.additionalSubscriptionsCount = additionalSubscriptionsCount
            self.relatedSubscriptions = relatedSubscriptions
        }
    }

    public var subscriptionId: String
    public var subscriptionName: String
    public var subscriptionCost: String
    public var iconName: String
    public var categoryColor: String

    public init(subscriptionId: String, subscriptionName: String, subscriptionCost: String, iconName: String, categoryColor: String) {
        self.subscriptionId = subscriptionId
        self.subscriptionName = subscriptionName
        self.subscriptionCost = subscriptionCost
        self.iconName = iconName
        self.categoryColor = categoryColor
    }
}

public struct RelatedSubscription: Codable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var cost: String
    public var billingDate: Date

    public init(id: String, name: String, cost: String, billingDate: Date) {
        self.id = id
        self.name = name
        self.cost = cost
        self.billingDate = billingDate
    }
}

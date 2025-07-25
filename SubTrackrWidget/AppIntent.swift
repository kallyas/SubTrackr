//
//  AppIntent.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget Configuration" }
    static var description: IntentDescription { "Configure what data to show in your SubTrackr widget." }

    @Parameter(title: "Widget Type", default: .summary)
    var widgetType: WidgetType
}

enum WidgetType: String, CaseIterable, AppEnum {
    case summary = "Summary"
    case upcomingRenewals = "Upcoming Renewals"
    case totalSpending = "Total Spending"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Type")
    
    static var caseDisplayRepresentations: [WidgetType: DisplayRepresentation] = [
        .summary: "Summary",
        .upcomingRenewals: "Upcoming Renewals",
        .totalSpending: "Total Spending"
    ]
}

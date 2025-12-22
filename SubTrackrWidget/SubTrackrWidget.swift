//
//  SubTrackrWidget.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import WidgetKit
import SwiftUI
import WidgetShared

// Widget data manager for reading widget data from shared UserDefaults
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupId = "group.com.iden.SubTrackr"
    private let dataKey = "widgetData"

    private init() {}

    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }

    func loadWidgetData() -> WidgetData? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }

        return widgetData
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SubTrackrEntry {
        SubTrackrEntry(date: Date(), configuration: ConfigurationAppIntent(), widgetData: .previewData)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SubTrackrEntry {
        let widgetData = WidgetDataManager.shared.loadWidgetData() ?? .empty
        return SubTrackrEntry(date: Date(), configuration: configuration, widgetData: widgetData)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SubTrackrEntry> {
        let widgetData = WidgetDataManager.shared.loadWidgetData() ?? .empty
        
        // Create entries for the next 4 hours to keep widget updated
        var entries: [SubTrackrEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SubTrackrEntry(date: entryDate, configuration: configuration, widgetData: widgetData)
            entries.append(entry)
        }

        // Update every hour
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SubTrackrEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let widgetData: WidgetData
}

struct SubTrackrWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SubTrackrEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                Text("SubTrackr")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if entry.widgetData.subscriptions.isEmpty {
                emptyView
            } else {
                switch entry.configuration.widgetType {
                case .summary:
                    summaryView
                case .upcomingRenewals:
                    upcomingRenewalsView
                case .totalSpending:
                    totalSpendingView
                }
            }
            
            Spacer()
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No Subscriptions")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Add subscriptions in the app.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Monthly Total")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(entry.widgetData.formattedMonthlyTotal)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("\(entry.widgetData.subscriptions.filter(\.isActive).count) active")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var upcomingRenewalsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Next Renewal")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let nextRenewal = entry.widgetData.upcomingRenewals.first {
                Text(nextRenewal.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(nextRenewal.nextBillingDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(nextRenewal.formattedCost)
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("No renewals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var totalSpendingView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("This Month")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(entry.widgetData.formattedMonthlyTotal)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            let activeCount = entry.widgetData.subscriptions.filter(\.isActive).count
            Text("\(activeCount) subscription\(activeCount == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MediumWidgetView: View {
    let entry: SubTrackrEntry
    
    var body: some View {
        VStack {
            if entry.widgetData.subscriptions.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var emptyView: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "list.bullet.clipboard")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No Subscriptions Yet")
                .font(.headline)
                .fontWeight(.semibold)
            Text("Open SubTrackr to add your first subscription and see it here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var contentView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)
                    Text("SubTrackr")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text("Monthly Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.widgetData.formattedMonthlyTotal)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(entry.widgetData.subscriptions.filter(\.isActive).count) active subscriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Upcoming Renewals")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(Array(entry.widgetData.upcomingRenewals.prefix(3)), id: \.id) { subscription in
                    HStack {
                        Image(systemName: subscription.iconName)
                            .foregroundColor(subscription.categoryColor)
                            .frame(width: 16)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(subscription.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text(subscription.nextBillingDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(subscription.formattedCost)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                
                if entry.widgetData.upcomingRenewals.isEmpty {
                    Text("No upcoming renewals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
}

struct LargeWidgetView: View {
    let entry: SubTrackrEntry
    
    var body: some View {
        VStack {
            if entry.widgetData.subscriptions.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var emptyView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Track Your Subscriptions")
                .font(.title2)
                .fontWeight(.bold)
            Text("Open the SubTrackr app to add your subscriptions. Your widget will automatically update to show your upcoming renewals and monthly spending.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                Text("SubTrackr")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("Updated \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.widgetData.formattedMonthlyTotal)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(entry.widgetData.subscriptions.filter(\.isActive).count) active subscriptions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Renewals")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(Array(entry.widgetData.upcomingRenewals.prefix(5)), id: \.id) { subscription in
                    HStack {
                        Image(systemName: subscription.iconName)
                            .foregroundColor(subscription.categoryColor)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscription.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text(subscription.nextBillingDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(subscription.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(subscription.formattedCost)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(subscription.billingCycle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                if entry.widgetData.upcomingRenewals.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No renewals in the next 7 days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Spacer()
        }
    }
}

struct SubTrackrWidget: Widget {
    let kind: String = "SubTrackrWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SubTrackrWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SubTrackr")
        .description("Keep track of your subscription renewals and spending.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var summary: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.widgetType = .summary
        return intent
    }
    
    fileprivate static var upcomingRenewals: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.widgetType = .upcomingRenewals
        return intent
    }
    
    fileprivate static var totalSpending: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.widgetType = .totalSpending
        return intent
    }
}


#Preview(as: .systemSmall) {
    SubTrackrWidget()
} timeline: {
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetData.previewData)
    SubTrackrEntry(date: .now, configuration: .upcomingRenewals, widgetData: WidgetData.previewData)
}

#Preview(as: .systemMedium) {
    SubTrackrWidget()
} timeline: {
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetData.previewData)
}

#Preview(as: .systemLarge) {
    SubTrackrWidget()
} timeline: {
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetData.previewData)
}

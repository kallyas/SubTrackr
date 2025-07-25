//
//  SubTrackrWidget.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import WidgetKit
import SwiftUI

// Shared data structures for widget
struct WidgetSubscription: Codable, Identifiable {
    let id: String
    let name: String
    let cost: Double
    let currencyCode: String
    let billingCycle: String
    let nextBillingDate: Date
    let category: String
    let iconName: String
    let isActive: Bool
    
    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: cost)) ?? "\(cost)"
    }
    
    var categoryColor: Color {
        switch category {
        case "Streaming": return .red
        case "Software": return .blue
        case "Fitness": return .green
        case "Gaming": return .purple
        case "Utilities": return .orange
        case "News": return .gray
        case "Music": return .pink
        case "Productivity": return .teal
        default: return .brown
        }
    }
}

struct WidgetData: Codable {
    let subscriptions: [WidgetSubscription]
    let monthlyTotal: Double
    let userCurrencyCode: String
    let lastUpdated: Date
    
    var upcomingRenewals: [WidgetSubscription] {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.nextBillingDate >= today &&
            subscription.nextBillingDate <= oneWeekFromNow
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    var formattedMonthlyTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = userCurrencyCode
        return formatter.string(from: NSNumber(value: monthlyTotal)) ?? "\(monthlyTotal)"
    }
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupId = "group.com.iden.SubTrackr"
    private let dataKey = "widgetData"
    
    private init() {}
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    func saveWidgetData(_ data: WidgetData) {
        guard let encoder = try? JSONEncoder().encode(data),
              let userDefaults = userDefaults else { return }
        
        userDefaults.set(encoder, forKey: dataKey)
        userDefaults.synchronize()
    }
    
    func loadWidgetData() -> WidgetData? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return getSampleData()
        }
        
        return widgetData
    }
    
    func getSampleData() -> WidgetData {
        let sampleSubscriptions = [
            WidgetSubscription(
                id: "1",
                name: "Netflix",
                cost: 15.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                category: "Streaming",
                iconName: "tv.fill",
                isActive: true
            ),
            WidgetSubscription(
                id: "2",
                name: "Spotify",
                cost: 9.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                category: "Music",
                iconName: "music.note",
                isActive: true
            ),
            WidgetSubscription(
                id: "3",
                name: "Adobe Creative",
                cost: 52.99,
                currencyCode: "USD",
                billingCycle: "Monthly",
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                category: "Software",
                iconName: "briefcase.fill",
                isActive: true
            )
        ]
        
        return WidgetData(
            subscriptions: sampleSubscriptions,
            monthlyTotal: 78.97,
            userCurrencyCode: "USD",
            lastUpdated: Date()
        )
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SubTrackrEntry {
        SubTrackrEntry(date: Date(), configuration: ConfigurationAppIntent(), widgetData: WidgetDataManager.shared.getSampleData())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SubTrackrEntry {
        let widgetData = WidgetDataManager.shared.loadWidgetData() ?? WidgetDataManager.shared.getSampleData()
        return SubTrackrEntry(date: Date(), configuration: configuration, widgetData: widgetData)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SubTrackrEntry> {
        let widgetData = WidgetDataManager.shared.loadWidgetData() ?? WidgetDataManager.shared.getSampleData()
        
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
            
            switch entry.configuration.widgetType {
            case .summary:
                summaryView
            case .upcomingRenewals:
                upcomingRenewalsView
            case .totalSpending:
                totalSpendingView
            }
            
            Spacer()
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
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
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: SubTrackrEntry
    
    var body: some View {
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
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
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
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetDataManager.shared.getSampleData())
    SubTrackrEntry(date: .now, configuration: .upcomingRenewals, widgetData: WidgetDataManager.shared.getSampleData())
}

#Preview(as: .systemMedium) {
    SubTrackrWidget()
} timeline: {
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetDataManager.shared.getSampleData())
}

#Preview(as: .systemLarge) {
    SubTrackrWidget()
} timeline: {
    SubTrackrEntry(date: .now, configuration: .summary, widgetData: WidgetDataManager.shared.getSampleData())
}

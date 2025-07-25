import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let dataManager = WidgetDataManager.shared
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), monthlyTotal: 127.50, upcomingRenewals: 3, activeSubscriptions: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let subscriptions = dataManager.getSampleSubscriptions()
        let monthlyTotal = dataManager.calculateMonthlyTotal(subscriptions: subscriptions)
        let upcomingRenewals = dataManager.getUpcomingRenewals(subscriptions: subscriptions)
        
        let entry = SimpleEntry(
            date: Date(),
            monthlyTotal: monthlyTotal,
            upcomingRenewals: upcomingRenewals,
            activeSubscriptions: subscriptions.count
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let subscriptions = dataManager.getSampleSubscriptions()
        let monthlyTotal = dataManager.calculateMonthlyTotal(subscriptions: subscriptions)
        let upcomingRenewals = dataManager.getUpcomingRenewals(subscriptions: subscriptions)
        
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Create entries for the next 4 hours
        for hourOffset in 0 ..< 4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(
                date: entryDate,
                monthlyTotal: monthlyTotal,
                upcomingRenewals: upcomingRenewals,
                activeSubscriptions: subscriptions.count
            )
            entries.append(entry)
        }

        // Update timeline every 4 hours
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let upcomingRenewals: Int
    let activeSubscriptions: Int
    
    var formattedMonthlyTotal: String {
        let currency = WidgetDataManager.shared.selectedCurrency
        return currency.formatAmount(monthlyTotal)
    }
}

struct SubTrackrWidgetEntryView : View {
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
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("SubTrackr")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(entry.formattedMonthlyTotal)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text("per month")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if entry.upcomingRenewals > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(entry.upcomingRenewals)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Text("\(entry.activeSubscriptions) active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Text("SubTrackr")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.formattedMonthlyTotal)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.activeSubscriptions)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if entry.upcomingRenewals > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.upcomingRenewals)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            Text("Due Soon")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Enhanced chart representation
            VStack(spacing: 3) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 16, height: CGFloat(8 + index * 4))
                }
            }
            .frame(width: 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Text("SubTrackr")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Monthly total card
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Total")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(entry.formattedMonthlyTotal)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Stats row
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Active Subscriptions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("\(entry.activeSubscriptions)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if entry.upcomingRenewals > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Due This Week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text("\(entry.upcomingRenewals)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Due This Week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Text("None")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
        )
    }
}

struct SubTrackrWidget: Widget {
    let kind: String = "SubTrackrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SubTrackrWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SubTrackr")
        .description("Keep track of your monthly subscription spending.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    SubTrackrWidget()
} timeline: {
    SimpleEntry(date: .now, monthlyTotal: 1247.89, upcomingRenewals: 3, activeSubscriptions: 12)
    SimpleEntry(date: .now, monthlyTotal: 2089.99, upcomingRenewals: 1, activeSubscriptions: 8)
}
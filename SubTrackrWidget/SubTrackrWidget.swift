import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), monthlyTotal: 127.50, upcomingRenewals: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), monthlyTotal: 127.50, upcomingRenewals: 3)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, monthlyTotal: 127.50, upcomingRenewals: 3)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let upcomingRenewals: Int
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
                Image(systemName: "calendar.badge.checkmark")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text("SubTrackr")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("$\(entry.monthlyTotal, specifier: "%.0f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("per month")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if entry.upcomingRenewals > 0 {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(entry.upcomingRenewals) due soon")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text("SubTrackr")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(entry.monthlyTotal, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                if entry.upcomingRenewals > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(entry.upcomingRenewals) subscriptions due soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Simple chart representation
            VStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(Double(index + 1) * 0.25))
                        .frame(width: 20, height: CGFloat(10 + index * 5))
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("SubTrackr")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Monthly total
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Total")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("$\(entry.monthlyTotal, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            // Upcoming renewals
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("Upcoming Renewals")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if entry.upcomingRenewals > 0 {
                    Text("\(entry.upcomingRenewals) subscriptions due this week")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text("No renewals this week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
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
    SimpleEntry(date: .now, monthlyTotal: 127.50, upcomingRenewals: 3)
    SimpleEntry(date: .now, monthlyTotal: 89.99, upcomingRenewals: 1)
}
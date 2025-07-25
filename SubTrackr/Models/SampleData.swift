import Foundation

struct SampleData {
    static let subscriptions: [Subscription] = [
        Subscription(
            name: "Netflix",
            cost: 13.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            category: .streaming,
            iconName: "tv.fill"
        ),
        Subscription(
            name: "Spotify",
            cost: 9.99,
            currency: .USD,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
            category: .music,
            iconName: "music.note"
        ),
        Subscription(
            name: "Adobe Creative Cloud",
            cost: 49.99,
            currency: .EUR,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date(),
            category: .software,
            iconName: "paintbrush.fill"
        ),
        Subscription(
            name: "Apple iCloud+",
            cost: 0.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date(),
            category: .utilities,
            iconName: "icloud.fill"
        ),
        Subscription(
            name: "YouTube Premium",
            cost: 11.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
            category: .streaming,
            iconName: "play.rectangle.fill"
        ),
        Subscription(
            name: "PlayStation Plus",
            cost: 59.99,
            billingCycle: .annual,
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            category: .gaming,
            iconName: "gamecontroller.fill"
        ),
        Subscription(
            name: "Microsoft 365",
            cost: 6.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -120, to: Date()) ?? Date(),
            category: .productivity,
            iconName: "doc.text.fill"
        ),
        Subscription(
            name: "Notion",
            cost: 8.00,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -25, to: Date()) ?? Date(),
            category: .productivity,
            iconName: "note.text"
        ),
        Subscription(
            name: "Apple Fitness+",
            cost: 9.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -40, to: Date()) ?? Date(),
            category: .fitness,
            iconName: "figure.run"
        ),
        Subscription(
            name: "Disney+",
            cost: 7.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -35, to: Date()) ?? Date(),
            category: .streaming,
            iconName: "sparkles.tv.fill"
        ),
        Subscription(
            name: "The New York Times",
            cost: 17.00,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -55, to: Date()) ?? Date(),
            category: .news,
            iconName: "newspaper.fill"
        ),
        Subscription(
            name: "Dropbox",
            cost: 9.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -80, to: Date()) ?? Date(),
            category: .utilities,
            iconName: "cloud.fill"
        ),
        Subscription(
            name: "GitHub Pro",
            cost: 4.00,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -50, to: Date()) ?? Date(),
            category: .software,
            iconName: "chevron.left.forwardslash.chevron.right"
        ),
        Subscription(
            name: "Amazon Prime",
            cost: 14.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date(),
            category: .streaming,
            iconName: "bag.fill"
        ),
        Subscription(
            name: "Hulu",
            cost: 7.99,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(),
            category: .streaming,
            iconName: "tv.and.hifispeaker.fill"
        )
    ]
    
    static func populateCloudKit() {
        let cloudKitService = CloudKitService.shared
        
        for subscription in subscriptions {
            cloudKitService.saveSubscription(subscription)
        }
    }
}
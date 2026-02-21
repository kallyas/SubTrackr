import Foundation

struct SubscriptionTemplate: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let category: SubscriptionCategory
    let typicalCostUSD: Double
    let billingCycle: BillingCycle
    
    var suggestedCostUSD: String {
        String(format: "%.2f", typicalCostUSD)
    }
    
    func suggestedCost(in currency: Currency) -> String {
        let converted = CurrencyManager.shared.convertToUserCurrency(typicalCostUSD, from: .USD)
        return currency.formatAmount(converted)
    }
    
    func typicalCostValue(in currency: Currency) -> Double {
        return CurrencyManager.shared.convertToUserCurrency(typicalCostUSD, from: .USD)
    }
}

extension SubscriptionTemplate {
    static let popularServices: [SubscriptionTemplate] = [
        SubscriptionTemplate(name: "Netflix", iconName: "play.rectangle.fill", category: .streaming, typicalCostUSD: 15.49, billingCycle: .monthly),
        SubscriptionTemplate(name: "Spotify", iconName: "music.note", category: .music, typicalCostUSD: 10.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Apple Music", iconName: "music.note.list", category: .music, typicalCostUSD: 10.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "YouTube Premium", iconName: "play.circle.fill", category: .streaming, typicalCostUSD: 13.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Disney+", iconName: "star.fill", category: .streaming, typicalCostUSD: 13.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "HBO Max", iconName: "tv.fill", category: .streaming, typicalCostUSD: 15.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Amazon Prime", iconName: "shippingbox.fill", category: .utilities, typicalCostUSD: 14.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Apple TV+", iconName: "tv", category: .streaming, typicalCostUSD: 6.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Hulu", iconName: "play.square.fill", category: .streaming, typicalCostUSD: 17.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Adobe Creative Cloud", iconName: "paintbrush.fill", category: .software, typicalCostUSD: 54.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Microsoft 365", iconName: "doc.fill", category: .software, typicalCostUSD: 9.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "GitHub Pro", iconName: "chevron.left.forwardslash.chevron.right", category: .software, typicalCostUSD: 4.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Dropbox", iconName: "externaldrive.fill", category: .software, typicalCostUSD: 11.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "iCloud+", iconName: "icloud.fill", category: .utilities, typicalCostUSD: 2.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Google One", iconName: "g.circle.fill", category: .utilities, typicalCostUSD: 2.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Notion", iconName: "square.split.2x2.fill", category: .productivity, typicalCostUSD: 10.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Slack", iconName: "bubble.left.and.bubble.right.fill", category: .productivity, typicalCostUSD: 8.75, billingCycle: .monthly),
        SubscriptionTemplate(name: "Discord", iconName: "gamecontroller.fill", category: .gaming, typicalCostUSD: 9.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Xbox Game Pass", iconName: "xbox.logo", category: .gaming, typicalCostUSD: 14.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "PlayStation Plus", iconName: "playstation.logo", category: .gaming, typicalCostUSD: 17.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Nintendo Switch Online", iconName: "n.circle.fill", category: .gaming, typicalCostUSD: 3.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Gym Membership", iconName: "figure.run", category: .fitness, typicalCostUSD: 29.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Peloton", iconName: "figure.outdoor.cycle", category: .fitness, typicalCostUSD: 44.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "The New York Times", iconName: "newspaper.fill", category: .news, typicalCostUSD: 17.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "The Wall Street Journal", iconName: "doc.text.fill", category: .news, typicalCostUSD: 38.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "LinkedIn Premium", iconName: "link.circle.fill", category: .productivity, typicalCostUSD: 29.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Amazon Kindle Unlimited", iconName: "book.fill", category: .other, typicalCostUSD: 11.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Audible", iconName: "headphones", category: .music, typicalCostUSD: 14.95, billingCycle: .monthly),
        SubscriptionTemplate(name: "VPN Service", iconName: "lock.shield.fill", category: .utilities, typicalCostUSD: 6.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Domain & Hosting", iconName: "globe", category: .utilities, typicalCostUSD: 10.00, billingCycle: .monthly),
        
        SubscriptionTemplate(name: "ChatGPT Plus", iconName: "brain.head.profile", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "ChatGPT Pro", iconName: "brain.head.profile", category: .software, typicalCostUSD: 200.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Claude Pro", iconName: "sparkles", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Claude Max", iconName: "sparkles", category: .software, typicalCostUSD: 100.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Perplexity Pro", iconName: "magnifyingglass", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Gemini Advanced", iconName: "sparkles.rectangle.stack", category: .software, typicalCostUSD: 19.99, billingCycle: .monthly),
        SubscriptionTemplate(name: "Microsoft Copilot Pro", iconName: "c.square", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "GitHub Copilot", iconName: "chevron.left.forwardslash.chevron.right", category: .software, typicalCostUSD: 10.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Cursor Pro", iconName: "terminal", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Windsurf Pro", iconName: "wind", category: .software, typicalCostUSD: 15.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Midjourney", iconName: "photo.artframe", category: .software, typicalCostUSD: 10.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "DALL-E Pro", iconName: "paintbrush.pointed", category: .software, typicalCostUSD: 20.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "ElevenLabs", iconName: "waveform", category: .software, typicalCostUSD: 22.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Runway ML", iconName: "film", category: .software, typicalCostUSD: 15.00, billingCycle: .monthly),
        SubscriptionTemplate(name: "Suno Pro", iconName: "music.note.list", category: .software, typicalCostUSD: 9.99, billingCycle: .monthly),
    ]
    
    static func search(_ query: String) -> [SubscriptionTemplate] {
        guard !query.isEmpty else { return popularServices }
        let lowercasedQuery = query.lowercased()
        return popularServices.filter { $0.name.lowercased().contains(lowercasedQuery) }
    }
}

import Foundation
import UIKit

struct SubscriptionURLProvider {
    
    static func getCancellationURL(for subscriptionName: String) -> URL? {
        let serviceName = subscriptionName.lowercased()
        
        // Common subscription service cancellation URLs
        let urlMappings: [String: String] = [
            // Streaming Services
            "netflix": "https://www.netflix.com/youraccount",
            "disney+": "https://www.disneyplus.com/account/subscription",
            "disney plus": "https://www.disneyplus.com/account/subscription",
            "hulu": "https://secure.hulu.com/account",
            "amazon prime": "https://www.amazon.com/gp/help/customer/display.html?nodeId=201357590",
            "youtube premium": "https://www.youtube.com/paid_memberships",
            "apple tv+": "https://support.apple.com/en-us/HT202039",
            "hbo max": "https://help.hbomax.com/Answer/Detail/000001139",
            "paramount+": "https://help.paramountplus.com/s/article/PD-How-do-I-cancel-my-subscription",
            
            // Music Services
            "spotify": "https://support.spotify.com/us/article/cancel-subscription/",
            "apple music": "https://support.apple.com/en-us/HT202039",
            "youtube music": "https://www.youtube.com/paid_memberships",
            "amazon music": "https://www.amazon.com/gp/help/customer/display.html?nodeId=201357590",
            
            // Software & Productivity
            "adobe creative cloud": "https://helpx.adobe.com/manage-account/using/cancel-subscription.html",
            "microsoft 365": "https://account.microsoft.com/services/",
            "office 365": "https://account.microsoft.com/services/",
            "notion": "https://www.notion.so/help/cancel-your-subscription",
            "canva": "https://www.canva.com/help/cancel-canva-pro/",
            "figma": "https://help.figma.com/hc/en-us/articles/360040328434",
            "github": "https://docs.github.com/en/billing/managing-billing-for-your-github-account/downgrading-your-github-subscription",
            
            // Cloud Storage
            "dropbox": "https://help.dropbox.com/account-billing/payments-billing/cancel-subscription",
            "google drive": "https://support.google.com/googleone/answer/9312428",
            "icloud": "https://support.apple.com/en-us/HT201238",
            "onedrive": "https://account.microsoft.com/services/",
            
            // Gaming
            "playstation plus": "https://www.playstation.com/en-us/support/subscriptions/cancel-playstation-subscriptions/",
            "xbox game pass": "https://support.xbox.com/help/subscriptions-billing/manage-subscriptions/cancel-xbox-subscriptions",
            "nintendo switch online": "https://en-americas-support.nintendo.com/app/answers/detail/a_id/41203",
            
            // News & Media
            "new york times": "https://help.nytimes.com/hc/en-us/articles/115014887628-Cancel-your-subscription",
            "wall street journal": "https://customercenter.wsj.com/",
            "washington post": "https://helpcenter.washingtonpost.com/hc/en-us/articles/115007248227-Cancel-my-subscription",
            
            // Fitness
            "apple fitness+": "https://support.apple.com/en-us/HT202039",
            "peloton": "https://support.onepeloton.com/hc/en-us/articles/203413595-Peloton-Digital-Membership",
            
            // Utilities
            "1password": "https://support.1password.com/cancel-subscription/",
            "lastpass": "https://support.logmeininc.com/lastpass/help/cancel-your-lastpass-subscription-lp010067"
        ]
        
        // Try to find exact match first
        if let urlString = urlMappings[serviceName],
           let url = URL(string: urlString) {
            return url
        }
        
        // Try partial matches
        for (key, urlString) in urlMappings {
            if serviceName.contains(key) || key.contains(serviceName) {
                if let url = URL(string: urlString) {
                    return url
                }
            }
        }
        
        // Fallback to generic search
        let searchQuery = "\(subscriptionName) cancel subscription".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let fallbackURLString = "https://www.google.com/search?q=\(searchQuery)"
        return URL(string: fallbackURLString)
    }
    
    static func openCancellationURL(for subscriptionName: String) {
        guard let url = getCancellationURL(for: subscriptionName) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    static func getManageSubscriptionURL(for subscriptionName: String) -> URL? {
        let serviceName = subscriptionName.lowercased()
        
        // Account management URLs (often same as cancellation but more general)
        let managementMappings: [String: String] = [
            "netflix": "https://www.netflix.com/youraccount",
            "spotify": "https://www.spotify.com/account/",
            "apple": "https://appleid.apple.com/account/manage",
            "microsoft": "https://account.microsoft.com/",
            "google": "https://myaccount.google.com/subscriptions",
            "amazon": "https://www.amazon.com/gp/css/account/info/view.html",
            "adobe": "https://account.adobe.com/",
            "github": "https://github.com/settings/billing"
        ]
        
        for (key, urlString) in managementMappings {
            if serviceName.contains(key) {
                return URL(string: urlString)
            }
        }
        
        return getCancellationURL(for: subscriptionName)
    }
}
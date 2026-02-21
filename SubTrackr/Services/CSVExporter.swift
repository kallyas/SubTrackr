import Foundation

class CSVExporter {
    static let shared = CSVExporter()
    
    private init() {}
    
    func exportSubscriptions(_ subscriptions: [Subscription]) -> String {
        var csv = "Name,Cost,Currency,Billing Cycle,Category,Start Date,Next Billing,Status,Archived,Trial, trial End Date\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for sub in subscriptions {
            let status = sub.isActive ? "Active" : "Inactive"
            let archived = sub.isArchived ? "Yes" : "No"
            let trial = sub.isTrial ? "Yes" : "No"
            let trialEnd = sub.trialEndDate.map { dateFormatter.string(from: $0) } ?? ""
            
            let row = [
                sub.name.replacingOccurrences(of: ",", with: ";"),
                String(format: "%.2f", sub.cost),
                sub.currency.code,
                sub.billingCycle.rawValue,
                sub.category.rawValue,
                dateFormatter.string(from: sub.startDate),
                dateFormatter.string(from: sub.nextBillingDate),
                status,
                archived,
                trial,
                trialEnd
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    func exportToFile(_ subscriptions: [Subscription]) -> URL? {
        let csv = exportSubscriptions(subscriptions)

        let fileName = "SubTrackr_Export_\(dateString()).csv"

        // Use Documents directory for better sharing compatibility
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentsDir.appendingPathComponent(fileName)

        do {
            // Remove old file if exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try csv.write(to: fileURL, atomically: true, encoding: .utf8)

            // Ensure file is readable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o644],
                ofItemAtPath: fileURL.path
            )

            return fileURL
        } catch {
            print("Error exporting CSV: \(error)")
            return nil
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

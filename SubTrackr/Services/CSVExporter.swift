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
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
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

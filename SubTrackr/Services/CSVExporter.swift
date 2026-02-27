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
    
    // MARK: - Import Functionality
    
    struct ImportResult {
        var subscriptions: [Subscription]
        var duplicates: [String]
        var errors: [String]
    }
    
    func importFromURL(_ url: URL) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw CSVImportError.invalidEncoding
        }
        
        return parseCSV(csvString)
    }
    
    private func parseCSV(_ csvString: String) -> ImportResult {
        var subscriptions: [Subscription] = []
        var duplicates: [String] = []
        var errors: [String] = []
        
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            errors.append("CSV file is empty or has no data rows")
            return ImportResult(subscriptions: [], duplicates: [], errors: errors)
        }
        
        let headers = parseCSVLine(lines[0]).map { $0.lowercased() }
        
        let nameIndex = headers.firstIndex(where: { $0.contains("name") || $0 == "subscription" || $0 == "service" })
        let costIndex = headers.firstIndex(where: { $0.contains("cost") || $0.contains("price") || $0.contains("amount") })
        let currencyIndex = headers.firstIndex(where: { $0 == "currency" || $0 == "currency code" })
        let billingCycleIndex = headers.firstIndex(where: { $0.contains("billing") || $0.contains("cycle") || $0.contains("frequency") })
        let categoryIndex = headers.firstIndex(where: { $0 == "category" || $0 == "type" })
        let dateIndex = headers.firstIndex(where: { $0.contains("date") || $0.contains("start") })
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for (index, line) in lines.dropFirst().enumerated() {
            let columns = parseCSVLine(line)
            
            guard let nameCol = nameIndex, nameCol < columns.count, !columns[nameCol].isEmpty else {
                errors.append("Row \(index + 2): Missing name")
                continue
            }
            
            let name = columns[nameCol].trimmingCharacters(in: .whitespaces)
            
            guard let costCol = costIndex, costCol < columns.count else {
                errors.append("Row \(index + 2): Missing cost for '\(name)'")
                continue
            }
            
            let costString = columns[costCol]
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: "£", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            guard let cost = Double(costString) else {
                errors.append("Row \(index + 2): Invalid cost '\(costString)' for '\(name)'")
                continue
            }
            
            var currency = CurrencyManager.shared.selectedCurrency
            if let currIdx = currencyIndex, currIdx < columns.count {
                let currCode = columns[currIdx].trimmingCharacters(in: .whitespaces).uppercased()
                if let foundCurrency = Currency.currency(for: currCode) {
                    currency = foundCurrency
                }
            }
            
            var billingCycle: BillingCycle = .monthly
            if let bcIdx = billingCycleIndex, bcIdx < columns.count {
                let bcString = columns[bcIdx].lowercased()
                billingCycle = parseBillingCycle(bcString)
            }
            
            var category: SubscriptionCategory = .other
            if let catIdx = categoryIndex, catIdx < columns.count {
                let catString = columns[catIdx].trimmingCharacters(in: .whitespaces)
                category = parseCategory(catString)
            }
            
            var startDate = Date()
            if let dateIdx = dateIndex, dateIdx < columns.count {
                let dateString = columns[dateIdx].trimmingCharacters(in: .whitespaces)
                if let parsedDate = dateFormatter.date(from: dateString) {
                    startDate = parsedDate
                }
            }
            
            let subscription = Subscription(
                name: name,
                cost: cost,
                currency: currency,
                billingCycle: billingCycle,
                startDate: startDate,
                category: category
            )
            
            subscriptions.append(subscription)
        }
        
        return ImportResult(subscriptions: subscriptions, duplicates: duplicates, errors: errors)
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
    
    private func parseBillingCycle(_ string: String) -> BillingCycle {
        let lowercased = string.lowercased()
        
        if lowercased.contains("week") {
            return .weekly
        } else if lowercased.contains("quarter") || lowercased.contains("3 month") {
            return .quarterly
        } else if lowercased.contains("semi") || lowercased.contains("6 month") {
            return .semiAnnual
        } else if lowercased.contains("year") || lowercased.contains("annual") {
            return .annual
        }
        
        return .monthly
    }
    
    private func parseCategory(_ string: String) -> SubscriptionCategory {
        let lowercased = string.lowercased()
        
        if lowercased.contains("stream") || lowercased.contains("video") || lowercased.contains("netflix") || lowercased.contains("hulu") || lowercased.contains("disney") {
            return .streaming
        } else if lowercased.contains("music") || lowercased.contains("spotify") || lowercased.contains("apple music") {
            return .music
        } else if lowercased.contains("software") || lowercased.contains("app") || lowercased.contains("cloud") || lowercased.contains("ai") || lowercased.contains("chatgpt") {
            return .software
        } else if lowercased.contains("gym") || lowercased.contains("fitness") || lowercased.contains("health") {
            return .fitness
        } else if lowercased.contains("game") || lowercased.contains("gaming") || lowercased.contains("xbox") || lowercased.contains("playstation") || lowercased.contains("nintendo") {
            return .gaming
        } else if lowercased.contains("news") || lowercased.contains("journal") || lowercased.contains("times") {
            return .news
        } else if lowercased.contains("utilit") || lowercased.contains("phone") || lowercased.contains("internet") || lowercased.contains("wifi") {
            return .utilities
        } else if lowercased.contains("productivity") || lowercased.contains("office") || lowercased.contains("business") {
            return .productivity
        }
        
        return .other
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

enum CSVImportError: LocalizedError {
    case invalidEncoding
    case emptyFile
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Unable to read the file. Please ensure it's a valid UTF-8 encoded CSV."
        case .emptyFile:
            return "The file appears to be empty."
        case .invalidFormat:
            return "The file format is not recognized as a valid CSV."
        }
    }
}

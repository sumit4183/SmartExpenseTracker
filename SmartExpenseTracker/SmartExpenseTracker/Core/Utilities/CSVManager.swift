import Foundation
import CoreData

class CSVManager {
    static func generateCSV(context: NSManagedObjectContext) -> String {
        // Fetch all transactions, sorted by date (newest first)
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            let transactions = try context.fetch(request)
            
            // CSV Header
            var csvString = "Date,Type,Category,Merchant,Amount,Currency,Base Amount (USD),Notes\n"
            
            // Date Formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            // Loop and append rows
            for t in transactions {
                let dateStr = dateFormatter.string(from: t.unwrappedDate)
                let typeStr = t.typeEnum.rawValue.capitalized
                let categoryStr = t.unwrappedCategory
                
                // Escape commas in Merchant and Notes fields
                let merchantStr = escapeStringForCSV(t.unwrappedDesc)
                
                // Formatted amounts
                let amountStr = String(format: "%.2f", t.amount)
                let currencyStr = t.unwrappedCurrencyCode
                let baseAmountStr = String(format: "%.2f", t.unwrappedBaseAmount)
                
                // Fallback for anomalies
                let notesStr = t.isAnomaly ? "Flagged as Anomaly" : ""
                
                let row = "\(dateStr),\(typeStr),\(categoryStr),\(merchantStr),\(amountStr),\(currencyStr),\(baseAmountStr),\(notesStr)\n"
                csvString.append(row)
            }
            
            return csvString
            
        } catch {
            print("Failed to fetch transactions for CSV: \(error)")
            return "Error initializing CSV Export"
        }
    }
    
    // Safely escapes text that might contain commas
    private static func escapeStringForCSV(_ text: String) -> String {
        var escaped = text
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}

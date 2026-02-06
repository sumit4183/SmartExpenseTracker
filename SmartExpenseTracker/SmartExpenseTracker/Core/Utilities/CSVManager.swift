import Foundation
import CoreData

struct CSVManager {
    static func generateCSV(context: NSManagedObjectContext) -> String {
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        var csvString = "Date,Description,Category,Type,Amount\n"
        
        do {
            let transactions = try context.fetch(request)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            for t in transactions {
                let date = dateFormatter.string(from: t.unwrappedDate)
                // Escape quotes in description
                let desc = (t.unwrappedDesc).replacingOccurrences(of: "\"", with: "\"\"")
                let category = t.unwrappedCategory
                let type = t.typeEnum.rawValue.capitalized
                let amount = String(format: "%.2f", t.amount)
                
                let line = "\"\(date)\",\"\(desc)\",\"\(category)\",\"\(type)\",\(amount)\n"
                csvString.append(line)
            }
        } catch {
            print("Error generating CSV: \(error)")
            return "Error generating CSV"
        }
        
        return csvString
    }
}

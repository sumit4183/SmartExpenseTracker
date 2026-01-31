import Foundation
import CoreData
import Combine

class TransactionListViewModel: ObservableObject {
    @Published var transactionSections: [String: [Transaction]] = [:]
    @Published var sectionHeaders: [String] = []
    @Published var searchText: String = "" {
        didSet {
            fetchData()
        }
    }
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    func fetchData() {
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        // Add Search Filter
        if !searchText.isEmpty {
            request.predicate = NSPredicate(format: "desc CONTAINS[cd] %@ OR category CONTAINS[cd] %@", searchText, searchText)
        }
        
        do {
            let transactions = try viewContext.fetch(request)
            groupTransactions(transactions)
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    private func groupTransactions(_ transactions: [Transaction]) {
        // Group by Date (formatted string)
        let grouped = Dictionary(grouping: transactions) { (transaction) -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            if Calendar.current.isDateInToday(transaction.unwrappedDate) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(transaction.unwrappedDate) {
                return "Yesterday"
            } else {
                return formatter.string(from: transaction.unwrappedDate)
            }
        }
        
        // Store
        self.transactionSections = grouped
        // Sort sections by date logic is a bit tricky with strings, 
        // so we sort based on the first transaction in each group
        self.sectionHeaders = grouped.keys.sorted { (dateStr1, dateStr2) -> Bool in
            let t1 = grouped[dateStr1]?.first?.unwrappedDate ?? Date()
            let t2 = grouped[dateStr2]?.first?.unwrappedDate ?? Date()
            return t1 > t2 // Newest dates first
        }
    }
    
    func deleteTransaction(at offsets: IndexSet, in section: String) {
        guard let transactions = transactionSections[section] else { return }
        
        for index in offsets {
            let transaction = transactions[index]
            viewContext.delete(transaction)
        }
        
        do {
            try viewContext.save()
            fetchData() // Refresh list
        } catch {
            print("Error deleting: \(error)")
        }
    }
}

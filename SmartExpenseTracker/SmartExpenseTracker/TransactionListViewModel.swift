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
    
    // Design Polish: Sorting & Filtering
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Date (New)"
        case oldest = "Date (Old)"
        case highest = "Amount (High)"
        case lowest = "Amount (Low)"
        var id: String { rawValue }
    }
    
    @Published var sortOption: SortOption = .newest { didSet { fetchData() } }
    @Published var selectedCategory: String? = nil { didSet { fetchData() } }
    @Published var categories: [String] = [
        "Food & Drink", "Groceries", "Transport", "Shopping",
        "Utilities", "Entertainment", "Health", "Travel", "Rent", "Salary"
    ] 
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    func fetchData() {
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        
        // 1. Predicates
        var predicates: [NSPredicate] = []
        
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "desc CONTAINS[cd] %@ OR category CONTAINS[cd] %@", searchText, searchText))
        }
        
        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // 2. Sorting
        switch sortOption {
        case .newest:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        case .oldest:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]
        case .highest:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.amount, ascending: false)]
        case .lowest:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.amount, ascending: true)]
        }
        
        do {
            let transactions = try viewContext.fetch(request)
            groupTransactions(transactions)
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    private func groupTransactions(_ transactions: [Transaction]) {
        // If sorting by Amount, don't chop into days (it makes ranking hard to see)
        if sortOption == .highest || sortOption == .lowest {
            self.transactionSections = ["All Transactions": transactions]
            self.sectionHeaders = ["All Transactions"]
            return
        }
        
        // Normal Date Grouping
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
        
        self.transactionSections = grouped
        // Sort headers based on Date option
        self.sectionHeaders = grouped.keys.sorted { (dateStr1, dateStr2) -> Bool in
            let t1 = grouped[dateStr1]?.first?.unwrappedDate ?? Date()
            let t2 = grouped[dateStr2]?.first?.unwrappedDate ?? Date()
            return sortOption == .oldest ? t1 < t2 : t1 > t2
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

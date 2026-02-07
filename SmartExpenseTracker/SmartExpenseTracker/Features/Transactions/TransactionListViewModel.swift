import Foundation
import CoreData
import Combine

class TransactionListViewModel: ObservableObject {
    @Published var searchText: String = ""
    
    // Design Polish: Sorting & Filtering
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case expense = "Expense"
        case income = "Income"
        var id: String { rawValue }
    }
    
    @Published var selectedFilter: FilterOption = .all
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Date (New)"
        case oldest = "Date (Old)"
        case highest = "Amount (High)"
        case lowest = "Amount (Low)"
        var id: String { rawValue }
    }
    
    @Published var sortOption: SortOption = .newest
    @Published var selectedCategory: String? = nil
    @Published var categories: [String] = [
        "Food & Drink", "Groceries", "Transport", "Shopping",
        "Utilities", "Entertainment", "Health", "Travel", "Rent", "Salary"
    ] 
    
    let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Computed Properties for FetchRequest
    
    var currentPredicate: NSPredicate {
        var predicates: [NSPredicate] = []
        
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "desc CONTAINS[cd] %@ OR category CONTAINS[cd] %@", searchText, searchText))
        }
        
        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if selectedFilter != .all {
            predicates.append(NSPredicate(format: "type == %@", selectedFilter.rawValue.lowercased()))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    var currentSortDescriptors: [NSSortDescriptor] {
        switch sortOption {
        case .newest:
            return [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        case .oldest:
            return [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]
        case .highest:
            // Secondary sort by date to keep consistent order
            return [
                NSSortDescriptor(keyPath: \Transaction.amount, ascending: false),
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
        case .lowest:
             return [
                NSSortDescriptor(keyPath: \Transaction.amount, ascending: true),
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        viewContext.delete(transaction)
        try? viewContext.save()
    }
}

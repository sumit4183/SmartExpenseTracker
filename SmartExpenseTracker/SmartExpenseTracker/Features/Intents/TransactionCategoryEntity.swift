import AppIntents

struct TransactionCategoryEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static let defaultQuery = TransactionCategoryQuery()
    
    var id: String
    var name: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TransactionCategoryQuery: EntityStringQuery {
    func entities(for identifiers: [TransactionCategoryEntity.ID]) async throws -> [TransactionCategoryEntity] {
        return TransactionCategoryEntity.allCategories.filter { identifiers.contains($0.id) }
    }
    
    func entities(matching string: String) async throws -> [TransactionCategoryEntity] {
        return TransactionCategoryEntity.allCategories.filter { $0.name.lowercased().contains(string.lowercased()) }
    }
    
    func suggestedEntities() async throws -> [TransactionCategoryEntity] {
        return TransactionCategoryEntity.allCategories
    }
}

extension TransactionCategoryEntity {
    static let allCategories: [TransactionCategoryEntity] = [
        "Food & Drink", "Groceries", "Transport", "Shopping", "Utilities", 
        "Entertainment", "Travel", "Health", "Rent", "Salary", "Other"
    ].map { TransactionCategoryEntity(id: $0, name: $0) }
}

import AppIntents
import CoreData

struct LogTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Transaction"
    static let description = IntentDescription("Logs a new transaction in Smart Expense Tracker.")
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Merchant")
    var merchant: String
    
    @Parameter(title: "Category")
    var category: TransactionCategoryEntity?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let persistenceController = await MainActor.run { PersistenceController.shared }
        let bgContext = persistenceController.container.newBackgroundContext()
        
        do {
            try await bgContext.perform {
                let transaction = Transaction(context: bgContext)
                transaction.id = UUID()
                transaction.amount = amount
                transaction.desc = merchant
                transaction.date = Date()
                transaction.isAnomaly = false
                
                
                if let providedCategory = category {
                    transaction.category = providedCategory.name
                } else {
                    transaction.category = "Other"
                }
                
                try bgContext.save()
            }
            
            let formattedAmount = String(format: "%.2f", amount)
            return .result(dialog: "Logged $\(formattedAmount) for \(merchant).")
        } catch {
            throw error
        }
    }
}

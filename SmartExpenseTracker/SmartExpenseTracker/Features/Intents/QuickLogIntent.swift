import AppIntents
import CoreData
import WidgetKit

@available(iOS 17.0, *)
struct QuickLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Log Expense"
    static var description = IntentDescription("Visually logs a small preset expense directly from the widget.")
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Merchant")
    var merchant: String
    
    @Parameter(title: "Category")
    var category: String
    
    init() {}
    
    init(amount: Double, merchant: String, category: String) {
        self.amount = amount
        self.merchant = merchant
        self.category = category
    }

    func perform() async throws -> some IntentResult {
        // AppIntents run on a background queue. We must safely access our MainActor PersistenceController.
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
                transaction.category = category
                
                try bgContext.save()
            }
            
            // Critical for interactive widgets: Tell the OS to refresh the timeline NOW so the new balance shows.
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
            
        } catch {
            throw error
        }
    }
}

import SwiftUI
import CoreData
import CoreML
import Combine

class AddTransactionViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var description: String = "" {
        didSet {
            // Trigger auto-categorization when user types
            predictCategory()
        }
    }
    @Published var selectedCategory: String = "Uncategorized"
    
    // Available categories (must match our model's classes for best results)
    let categories = [
        "Food & Drink", "Groceries", "Transport", "Shopping",
        "Utilities", "Entertainment", "Health", "Travel", "Rent", "Salary"
    ]
    
    private let viewContext: NSManagedObjectContext
    private var categorizer: ExpenseCategorizer?
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Load the ML Model
        do {
            let config = MLModelConfiguration()
            self.categorizer = try ExpenseCategorizer(configuration: config)
        } catch {
            print("Failed to load ML Model: \(error)")
        }
    }
    
    // MARK: - ML Inference
    private func predictCategory() {
        guard !description.isEmpty, let model = categorizer else { return }
        
        // Simple heuristic: don't predict for very short strings
        guard description.count > 2 else { return }
        
        do {
            // The model expects a "text" input
            let prediction = try model.prediction(text: description)
            
            // UI Update must be on Main Thread
            // Add a small animation to show "magic"
            withAnimation {
                self.selectedCategory = prediction.label
            }
        } catch {
            print("Prediction error: \(error)")
        }
    }
    
    // MARK: - Core Data Actions
    func saveTransaction() {
        guard let amountDouble = Double(amount) else { return }
        
        let newTransaction = Transaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.date = Date()
        newTransaction.amount = amountDouble
        newTransaction.desc = description
        newTransaction.category = selectedCategory
        newTransaction.isAnomaly = false 
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save transaction: \(error)")
        }
    }
}

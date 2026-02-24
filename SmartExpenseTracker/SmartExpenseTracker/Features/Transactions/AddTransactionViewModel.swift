import SwiftUI
import CoreData
import CoreML
import Combine
import WidgetKit

class AddTransactionViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var type: TransactionType = .expense {
        didSet {
            // Smart defaults when switching types
            if type == .income {
                selectedCategory = "Salary"
            } else {
                selectedCategory = "Uncategorized"
                predictCategory() // Re-run prediction for expense
            }
        }
    }
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
    private var editingTransaction: Transaction?
    
    init(context: NSManagedObjectContext, transaction: Transaction? = nil) {
        self.viewContext = context
        self.editingTransaction = transaction
        
        // Load the ML Model
        do {
            let config = MLModelConfiguration()
            self.categorizer = try ExpenseCategorizer(configuration: config)
        } catch {
            print("Failed to load ML Model: \(error)")
        }
        
        // Populate if editing
        if let t = transaction {
            self.amount = String(format: "%.2f", t.amount) // Format nicely
            self.type = t.typeEnum
            self.description = t.unwrappedDesc
            self.selectedCategory = t.unwrappedCategory
        }
    }
    
    // MARK: - ML Inference
    private func predictCategory() {
        // AI Logic: Only predict for Expenses. Income is simple.
        guard type == .expense else { return }
        
        // Skip prediction if editing and description hasn't changed majorly (simplified: just skip for now to avoid overwriting user edits)
        // Better: Only predict if description is CHANGING. 
        // Current implementation calls this via didSet, so it handles changes.
        
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
    
    // Anomaly State
    @Published var showAnomalyAlert: Bool = false
    @Published var anomalyMessage: String = ""
    private var isAnomalyConfirmed: Bool = false
    
    // MARK: - Core Data Actions
    @discardableResult
    func saveTransaction() -> Bool {
        guard let amountDouble = Double(amount) else { return false }
        
        // 1. Anomaly Check (Guardian)
        // Skip anomalies for edits to avoid annoyance
        if editingTransaction == nil && !isAnomalyConfirmed {
            if checkForAnomaly(amount: amountDouble, category: selectedCategory) {
                return false // Stop save, trigger UI alert
            }
        }
        
        // 2. Save
        let transaction: Transaction
        if let existing = editingTransaction {
            transaction = existing
        } else {
            transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.date = Date()
            transaction.isAnomaly = isAnomalyConfirmed
        }
        
        transaction.amount = amountDouble
        transaction.desc = description
        transaction.category = selectedCategory
        transaction.typeEnum = type
        
        do {
            try viewContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            print("Failed to save transaction: \(error)")
            return false
        }
    }
    
    func confirmAnomalySave() {
        isAnomalyConfirmed = true
        _ = saveTransaction()
        isAnomalyConfirmed = false // Reset
    }
    
    // MARK: - Anomaly Logic (Z-Score)
    private func checkForAnomaly(amount: Double, category: String) -> Bool {
        // Fetch history for this category
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let history = try viewContext.fetch(request)
            
            // Need decent sample size (e.g. at least 5 coffee runs)
            guard history.count >= 5 else { return false }
            
            let amounts = history.map { $0.amount }
            let sum = amounts.reduce(0, +)
            let mean = sum / Double(amounts.count)
            
            // Standard Deviation
            let sumSquaredDiffs = amounts.map { pow($0 - mean, 2) }.reduce(0, +)
            let stdDev = sqrt(sumSquaredDiffs / Double(amounts.count))
            
            // Z-Score: How many deviations away is this new amount?
            // If stdDev is tiny (stable spending), minor deviations trigger it.
            // Let's enforce a minimum threshold too (e.g. $10 variance) to avoid noise.
            let effectiveStdDev = max(stdDev, 5.0) 
            
            let zScore = (amount - mean) / effectiveStdDev
            
            // Threshold: > 2.0 (Top 2.5% of outliers in normal distribution)
            if zScore > 2.0 {
                let percentDiff = Int(((amount - mean) / mean) * 100)
                self.anomalyMessage = "This is \(percentDiff)% higher than your average \(category) spend of \(mean.formatted(.currency(code: "USD")))."
                self.showAnomalyAlert = true
                return true
            }
            
        } catch {
            print("Anomaly check failed: \(error)")
        }
        
        return false
    }
}

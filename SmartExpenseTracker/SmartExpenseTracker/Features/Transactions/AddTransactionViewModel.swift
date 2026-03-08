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
    private var predictedCategory: String? = nil
    @Published var selectedCurrency: String = "USD"
    @Published var date: Date = Date()
    
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
            self.selectedCurrency = t.unwrappedCurrencyCode
            self.date = t.unwrappedDate
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
            // STEP 1: Check Local Overrides (Continuous Learning)
            let overrideRequest = NSFetchRequest<CategoryOverride>(entityName: "CategoryOverride")
            // Strict match on merchant name
            overrideRequest.predicate = NSPredicate(format: "merchantName == [c] %@", description)
            overrideRequest.fetchLimit = 1
            
            if let overrides = try? viewContext.fetch(overrideRequest), let firstOverride = overrides.first {
                // We learned from the user previously! Use their preferred category.
                if let learnedCategory = firstOverride.userPreferredCategory {
                    withAnimation {
                        self.selectedCategory = learnedCategory
                        self.predictedCategory = learnedCategory
                    }
                    return // Skip CoreML entirely
                }
            }
            
            // STEP 2: Fallback to CoreML Model
            let prediction = try model.prediction(text: description)
            
            // UI Update must be on Main Thread
            withAnimation {
                self.selectedCategory = prediction.label
                self.predictedCategory = prediction.label
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
        
        let baseAmount = ExchangeRateManager.shared.convertToBase(amount: amountDouble, from: selectedCurrency)
        
        // 1. Anomaly Check (Guardian)
        // Skip anomalies for edits to avoid annoyance
        if editingTransaction == nil && !isAnomalyConfirmed {
            if checkForAnomaly(baseAmount: baseAmount, category: selectedCategory) {
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
            transaction.date = date
            transaction.isAnomaly = isAnomalyConfirmed
        }
        
        transaction.amount = amountDouble
        transaction.currencyCode = selectedCurrency
        transaction.baseCurrencyAmount = baseAmount
        transaction.desc = description
        transaction.category = selectedCategory
        transaction.typeEnum = type
        
        // --- 3. ON-DEVICE LEARNING (Epic 3, Phase 3.2) ---
        // If the resulting category is different than what the AI predicted,
        // it means the user manually corrected the AI. We save this override.
        if type == .expense,
           let predicted = predictedCategory,
           predicted != selectedCategory,
           !description.isEmpty {
            
            // First check if an override already exists for this exact merchant to avoid duplicates
            let overrideRequest = NSFetchRequest<CategoryOverride>(entityName: "CategoryOverride")
            // Strict match on merchant name
            overrideRequest.predicate = NSPredicate(format: "merchantName == [c] %@", description)
            
            do {
                let existingOverrides = try viewContext.fetch(overrideRequest)
                if let existing = existingOverrides.first {
                    // Update existing rule
                    existing.userPreferredCategory = selectedCategory
                } else {
                    // Create new learned rule
                    let newOverride = CategoryOverride(context: viewContext)
                    newOverride.id = UUID()
                    newOverride.merchantName = description
                    newOverride.userPreferredCategory = selectedCategory
                }
            } catch {
                print("Failed to query existing overrides: \(error)")
            }
        }
        
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
    private func checkForAnomaly(baseAmount: Double, category: String) -> Bool {
        // Fetch history for this category
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let history = try viewContext.fetch(request)
            
            // Need decent sample size (e.g. at least 5 coffee runs)
            guard history.count >= 5 else { return false }
            
            let amounts = history.map { $0.unwrappedBaseAmount }
            let sum = amounts.reduce(0, +)
            let mean = sum / Double(amounts.count)
            
            // Standard Deviation
            let sumSquaredDiffs = amounts.map { pow($0 - mean, 2) }.reduce(0, +)
            let stdDev = sqrt(sumSquaredDiffs / Double(amounts.count))
            
            // Z-Score: How many deviations away is this new amount?
            // If stdDev is tiny (stable spending), minor deviations trigger it.
            // Let's enforce a minimum threshold too (e.g. $10 variance) to avoid noise.
            let effectiveStdDev = max(stdDev, 5.0) 
            
            let zScore = (baseAmount - mean) / effectiveStdDev
            
            // Threshold: > 2.0 (Top 2.5% of outliers in normal distribution)
            if zScore > 2.0 {
                let percentDiff: Int
                if mean > 0 {
                    percentDiff = Int(((baseAmount - mean) / mean) * 100)
                } else {
                    percentDiff = 100 // Safe fallback
                }
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

import Foundation
import CoreData
import Combine
import CoreML

class DashboardViewModel: ObservableObject {
    @Published var recentTransactions: [Transaction] = []
    @Published var totalSpend: Double = 0.0
    @Published var predictedSpend: Double = 0.0
    @Published var spendingByCategory: [String: Double] = [:]
    
    // Models
    // private var categorizer: ExpenseCategorizer?
    // removed: private var forecaster: ExpenseForecaster?
    
    // Learning State
    @Published var isLearning: Bool = true
    @Published var learningProgress: String = ""
    
    var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    func fetchData() {
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            let transactions = try viewContext.fetch(request)
            DispatchQueue.main.async {
                self.recentTransactions = transactions
                self.calculateMetrics(transactions: transactions)
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    private func calculateMetrics(transactions: [Transaction]) {
        // 1. Total Spend
        self.totalSpend = transactions.reduce(0) { $0 + $1.amount }
        
        // 2. Spending by Category
        var catTotals: [String: Double] = [:]
        for t in transactions {
            let cat = t.unwrappedCategory
            catTotals[cat, default: 0] += t.amount
        }
        self.spendingByCategory = catTotals
        
        // 3. Personalized Forecast (On-Device Statistical Learning)
        let minRequired = 5
        
        if transactions.count < minRequired {
            // Cold Start: Not enough data to be smart yet
            self.isLearning = true
            self.learningProgress = "\(transactions.count)/\(minRequired)"
            self.predictedSpend = 0.0
        } else {
            self.isLearning = false
            
            // Algorithm: "What do I usually spend on this day of the week?"
            let weekday = Calendar.current.component(.weekday, from: Date())
            
            // Filter: Only past transactions from the same weekday (e.g., all previous Saturdays)
            let relevantTransactions = transactions.filter {
                Calendar.current.component(.weekday, from: $0.unwrappedDate) == weekday
            }
            
            if relevantTransactions.isEmpty {
                self.predictedSpend = 0.0
            } else {
                // Aggregate: Group by specific Date to get Daily Totals
                // (e.g. Sat Jan 1: $10+$5=$15; Sat Jan 8: $20. Average = $17.50)
                let groupedByDate = Dictionary(grouping: relevantTransactions) { t in
                    Calendar.current.startOfDay(for: t.unwrappedDate)
                }
                
                let dailyTotals = groupedByDate.map { $0.value.reduce(0) { $0 + $1.amount } }
                let total = dailyTotals.reduce(0, +)
                let average = total / Double(dailyTotals.count)
                
                self.predictedSpend = average
            }
        }
    }

    func save() {
        do {
            try viewContext.save()
            fetchData()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

import Foundation
import CoreData
import Combine
import CoreML

class DashboardViewModel: ObservableObject {
    @Published var recentTransactions: [Transaction] = []
    @Published var totalSpend: Double = 0.0
    @Published var predictedSpend: Double = 0.0
    @Published var spendingByCategory: [String: Double] = [:]
    
    // Core ML Models
    // private var forecaster: ExpenseForecaster?
    // private var categorizer: ExpenseCategorizer?
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
        
        // Load Models (Placeholder for when you have dragged them in)
        // do {
        //     forecaster = try ExpenseForecaster(configuration: MLModelConfiguration())
        //     categorizer = try ExpenseCategorizer(configuration: MLModelConfiguration())
        // } catch {
        //     print("Failed to load ML Models: \(error)")
        // }
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
        
        // 3. Simple Forecast (Mock for now, will connect ML next)
        // Check if we can run inference
        // let dayOfWeek = Double(Calendar.current.component(.weekday, from: Date()) - 1)
        // if let prediction = try? forecaster?.prediction(day_of_week: dayOfWeek) {
        //      self.predictedSpend = prediction.predicted_amount
        // }
    }
    
    func addSampleTransaction() {
        let t = Transaction(context: viewContext)
        t.id = UUID()
        t.amount = Double.random(in: 5...50)
        t.date = Date()
        t.desc = "New Entry"
        t.category = "Uncategorized"
        save()
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

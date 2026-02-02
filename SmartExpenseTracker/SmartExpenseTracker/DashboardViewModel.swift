import Foundation
import SwiftUI
import Combine
import CoreML
import CoreData

struct CategorySpend: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    var color: Color {
        // Match user's specific categories
        switch category {
        case "Food & Drink", "Dining", "Coffee": return .orange
        case "Groceries", "Grocery": return .green
        case "Shopping": return .pink
        case "Travel", "Transport": return .blue
        case "Bills", "Utilities", "Rent": return .purple
        case "Entertainment", "Movies": return .indigo
        case "Health", "Gym": return .red
        default: return .gray
        }
    }
}

struct DailySpend: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

class DashboardViewModel: ObservableObject {
    @Published var recentTransactions: [Transaction] = []
    @Published var totalSpend: Double = 0.0
    @Published var currentMonthSpend: Double = 0.0 // For Budget
    @Published var predictedSpend: Double = 0.0
    @Published var spendingByCategory: [String: Double] = [:]
    @Published var weeklyData: [DailySpend] = [] // For Bar Chart
    @Published var categoryData: [CategorySpend] = [] // For Pie Chart
    @Published var subscriptions: [Subscription] = [] // Detected Subscriptions
    
    // Budgeting (Power Feature)
    @Published var monthlyBudget: Double {
        didSet {
            UserDefaults.standard.set(monthlyBudget, forKey: "monthlyBudget")
        }
    }
    
    // Models
    // private var categorizer: ExpenseCategorizer?
    // removed: private var forecaster: ExpenseForecaster?
    
    // Learning State
    @Published var isLearning: Bool = true
    @Published var learningProgress: String = ""
    
    var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.monthlyBudget = UserDefaults.standard.double(forKey: "monthlyBudget")
        if self.monthlyBudget == 0 { self.monthlyBudget = 2000.0 } // Default
        fetchData()
    }
    
    func fetchData() {
        // A. UI DATA (Main Thread, Fast, Limited)
        let uiRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
        uiRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        uiRequest.fetchLimit = 20 // Only show top 20 on dash
        
        do {
            self.recentTransactions = try viewContext.fetch(uiRequest)
        } catch {
            print("Error fetching UI data: \(error)")
        }
        
        // B. ANALYTICS DATA (Background Thread, Heavy, All Data)
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.perform {
            let analyticsRequest = NSFetchRequest<Transaction>(entityName: "Transaction")
            // No sort needed for math, usually faster
            
            do {
                let allTransactions = try bgContext.fetch(analyticsRequest)
                
                // Perform heavy math on background thread
                // We need to capture these results and pass them back
                let metrics = self.calculateMetricsBlocking(transactions: allTransactions)
                let subs = self.detectSubscriptionsBlocking(transactions: allTransactions)
                
                DispatchQueue.main.async {
                    // Update UI
                    self.totalSpend = metrics.total
                    self.currentMonthSpend = metrics.month
                    self.spendingByCategory = metrics.catTotals
                    self.categoryData = metrics.pieData
                    self.weeklyData = metrics.barData
                    self.predictedSpend = metrics.forecast
                    
                    self.subscriptions = subs
                    
                    // Update learning state
                    if allTransactions.count < 5 {
                        self.isLearning = true
                        self.learningProgress = "\(allTransactions.count)/5"
                    } else {
                        self.isLearning = false
                    }
                }
            } catch {
                print("Error calculating analytics: \(error)")
            }
        }
    }
    
    // Pure function running on background thread
    private func calculateMetricsBlocking(transactions: [Transaction]) -> MetricsResult {
        var result = MetricsResult()
        
        // 1. Total Spend (All Time)
        result.total = transactions.reduce(0) { $0 + $1.amount }
        
        // 1b. Current Month Spend (For Budget)
        let calendar = Calendar.current
        let now = Date()
        result.month = transactions
            .filter { calendar.isDate($0.unwrappedDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        
        // 2. Spending by Category
        var catTotals: [String: Double] = [:]
        for t in transactions {
            let cat = t.unwrappedCategory
            catTotals[cat, default: 0] += t.amount
        }
        result.catTotals = catTotals
        
        // Convert to Chart Data
        result.pieData = catTotals.map { key, value in
            CategorySpend(category: key, amount: value)
        }.sorted(by: { $0.amount > $1.amount })
        
        // 3. Weekly Chart Data (Rolling 7 Days)
        var last7Days: [DailySpend] = []
        // calendar reused from above
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            
            // Sum transactions for this specific day
            let dailyTotal = transactions
                .filter { calendar.isDate($0.unwrappedDate, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            
            last7Days.append(DailySpend(date: startOfDay, amount: dailyTotal))
        }
        result.barData = last7Days.reversed()
        
        // 4. Personalized Forecast
        let minRequired = 5
        if transactions.count >= minRequired {
            let weekday = Calendar.current.component(.weekday, from: Date())
            let relevantTransactions = transactions.filter {
                Calendar.current.component(.weekday, from: $0.unwrappedDate) == weekday
            }
            
            if !relevantTransactions.isEmpty {
                let groupedByDate = Dictionary(grouping: relevantTransactions) { t in
                    Calendar.current.startOfDay(for: t.unwrappedDate)
                }
                let dailyTotals = groupedByDate.map { $0.value.reduce(0) { $0 + $1.amount } }
                let total = dailyTotals.reduce(0, +)
                result.forecast = total / Double(dailyTotals.count)
            }
        }
        
        return result
    }

    private func detectSubscriptionsBlocking(transactions: [Transaction]) -> [Subscription] {
        let grouped = Dictionary(grouping: transactions, by: { $0.unwrappedDesc })
        var detected: [Subscription] = []
        
        for (merchant, txs) in grouped {
            if txs.count > 1 {
                let amountCounts = Dictionary(grouping: txs, by: { $0.amount })
                if let frequentAmount = amountCounts.max(by: { $0.value.count < $1.value.count }),
                   frequentAmount.value.count > 1 {
                    detected.append(Subscription(
                        merchant: merchant,
                        amount: frequentAmount.key,
                        occurences: frequentAmount.value.count
                    ))
                }
            }
        }
        return detected.sorted(by: { $0.amount > $1.amount })
    }
}

// Helper Struct for passing data back from Background Thread
struct MetricsResult {
    var total: Double = 0.0
    var month: Double = 0.0
    var catTotals: [String: Double] = [:]
    var pieData: [CategorySpend] = []
    var barData: [DailySpend] = []
    var forecast: Double = 0.0
}

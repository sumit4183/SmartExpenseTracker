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
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            let transactions = try viewContext.fetch(request)
            DispatchQueue.main.async {
                self.recentTransactions = transactions
                self.calculateMetrics(transactions: transactions)
                self.detectSubscriptions(transactions: transactions)
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    private func calculateMetrics(transactions: [Transaction]) {
        // 1. Total Spend (All Time)
        self.totalSpend = transactions.reduce(0) { $0 + $1.amount }
        
        // 1b. Current Month Spend (For Budget)
        let calendar = Calendar.current
        let now = Date()
        self.currentMonthSpend = transactions
            .filter { calendar.isDate($0.unwrappedDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        
        // 2. Spending by Category
        var catTotals: [String: Double] = [:]
        for t in transactions {
            let cat = t.unwrappedCategory
            catTotals[cat, default: 0] += t.amount
        }
        self.spendingByCategory = catTotals
        
        // Convert to Chart Data
        self.categoryData = catTotals.map { key, value in
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
        self.weeklyData = last7Days.reversed() // Oldest -> Newest
        
        // 4. Personalized Forecast (On-Device Statistical Learning)
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

// MARK: - Subscription Engine
struct Subscription: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let occurences: Int
    // Simple logic: If we see it > 1 times with same amount, it's a "Potential Subscription"
}

extension DashboardViewModel {
    func detectSubscriptions(transactions: [Transaction]) {
        // Group by Description (Approx Merchant)
        let grouped = Dictionary(grouping: transactions, by: { $0.unwrappedDesc })
        
        var detected: [Subscription] = []
        
        for (merchant, txs) in grouped {
            // Check if multiple occurrences
            if txs.count > 1 {
                // Check if amounts are consistent (or mostly consistent)
                // For MVP, just check if the most common amount appears > 1 times
                let amountCounts = Dictionary(grouping: txs, by: { $0.amount })
                if let frequentAmount = amountCounts.max(by: { $0.value.count < $1.value.count }),
                   frequentAmount.value.count > 1 {
                    
                    // It's a candidate
                    detected.append(Subscription(
                        merchant: merchant,
                        amount: frequentAmount.key,
                        occurences: frequentAmount.value.count
                    ))
                }
            }
        }
        
        // Sort by amount (Big subs first)
        self.subscriptions = detected.sorted(by: { $0.amount > $1.amount })
    }
}

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
    @Published var totalIncome: Double = 0.0
    @Published var netSavings: Double = 0.0
    @Published var currentMonthSpend: Double = 0.0 // For Budget
    @Published var predictedSpend: Double = 0.0
    @Published var spendingByCategory: [String: Double] = [:]
    @Published var weeklyData: [DailySpend] = [] // For Bar Chart
    @Published var categoryData: [CategorySpend] = [] // For Pie Chart
    @Published var subscriptions: [ExpenseSubscription] = [] // Detected Subscriptions
    
    // AI Explainability (Phase 2.4)
    @Published var forecastConfidence: Double = 0.0 // 0.0 to 1.0
    @Published var forecastReason: String = "Gathering data..."
    
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
                    self.totalIncome = metrics.totalIncome
                    self.netSavings = metrics.netSavings
                    self.currentMonthSpend = metrics.month
                    self.spendingByCategory = metrics.catTotals
                    self.categoryData = metrics.pieData
                    self.weeklyData = metrics.barData
                    self.predictedSpend = metrics.forecast
                    self.forecastConfidence = metrics.forecastConfidence
                    self.forecastReason = metrics.forecastReason
                    
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
}

// MARK: - Subscription Engine
struct ExpenseSubscription: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let occurences: Int
    // Simple logic: If we see it > 1 times with same amount, it's a "Potential Subscription"
}

extension DashboardViewModel {
    
    // Pure function running on background thread
    private func calculateMetricsBlocking(transactions: [Transaction]) -> MetricsResult {
        var result = MetricsResult()
        
        let expenses = transactions.filter { $0.typeEnum == .expense }
        let incomes = transactions.filter { $0.typeEnum == .income }
        
        // 1. Total Spend & Income (All Time)
        result.total = expenses.reduce(0) { $0 + $1.amount }
        result.totalIncome = incomes.reduce(0) { $0 + $1.amount }
        result.netSavings = result.totalIncome - result.total
        
        // 1b. Current Month Spend (For Budget) - EXPENSES ONLY
        let calendar = Calendar.current
        let now = Date()
        result.month = expenses
            .filter { calendar.isDate($0.unwrappedDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        
        // 2. Spending by Category - EXPENSES ONLY
        var catTotals: [String: Double] = [:]
        for t in expenses {
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
        let minRequired = 3 // Reduced threshold for demo
        result.forecast = 0.0
        result.forecastConfidence = 0.0
        result.forecastReason = "Not enough data"
        
        if transactions.count >= minRequired {
            let weekday = Calendar.current.component(.weekday, from: Date())
            let weekdayName = DateFormatter().weekdaySymbols[weekday - 1]
            
            let relevantTransactions = transactions.filter {
                Calendar.current.component(.weekday, from: $0.unwrappedDate) == weekday
            }
            
            if !relevantTransactions.isEmpty {
                let groupedByDate = Dictionary(grouping: relevantTransactions) { t in
                    Calendar.current.startOfDay(for: t.unwrappedDate)
                }
                
                // Get daily totals for this weekday (e.g., [15.0, 20.0, 18.0])
                let dailyTotals = groupedByDate.map { $0.value.reduce(0) { $0 + $1.amount } }
                
                // 1. Mean
                let total = dailyTotals.reduce(0, +)
                let mean = total / Double(dailyTotals.count)
                
                if dailyTotals.count > 1 {
                    // 2. Standard Deviation
                    let variance = dailyTotals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(dailyTotals.count)
                    let stdDev = sqrt(variance)
                    
                    // 3. Coefficient of Variation (Volatility)
                    // If mean is 0, avoid division by zero
                    let cv = mean > 0 ? stdDev / mean : 0
                    
                    // 4. Confidence Score (Higher volatility = Lower confidence)
                    // CV of 0.0 (Perfect) -> 100%
                    // CV of 0.5 (High variance) -> 50%
                    // CV of 1.0+ (Erratic) -> 20%
                    let rawConfidence = max(0.2, 1.0 - cv)
                    
                    // Penalty for low data count
                    let countPenalty = min(1.0, Double(dailyTotals.count) / 10.0) // 10 samples for full trust
                    
                    result.forecast = mean
                    result.forecastConfidence = rawConfidence * countPenalty
                    
                    // 5. Reasoning
                    if cv < 0.2 {
                        result.forecastReason = "Your spending on \(weekdayName)s is very consistent."
                    } else if cv < 0.5 {
                        result.forecastReason = "Spending on \(weekdayName)s varies slightly."
                    } else {
                        result.forecastReason = "Your \(weekdayName) spending is erratic (High Variance)."
                    }
                } else {
                    // Single data point
                    result.forecast = mean
                    result.forecastConfidence = 0.4 // Low trust
                    result.forecastReason = "Only one past \(weekdayName) found."
                }
            }
        }
        
        return result
    }

    private func detectSubscriptionsBlocking(transactions: [Transaction]) -> [ExpenseSubscription] {
        // Filter for expenses only
        let expenses = transactions.filter { $0.typeEnum == .expense }
        
        // 1. Normalize Descriptions (Simple Fuzzy Match)
        // e.g. "Netflix #1123" -> "netflix"
        func normalize(_ text: String) -> String {
            return text.lowercased()
                .components(separatedBy: CharacterSet.decimalDigits).joined()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var candidates: [String: [Transaction]] = [:]
        
        for t in expenses {
            let key = normalize(t.unwrappedDesc)
            // Group by Merchant + Rough Amount (Round to nearest integer to handle currency fluctuate)
            let amountKey = "\(key)_\(Int(t.amount))"
            candidates[amountKey, default: []].append(t)
        }
        
        var detected: [ExpenseSubscription] = []
        
        for (_, txs) in candidates {
            // Need at least 2 occurrences
            guard txs.count > 1 else { continue }
            
            // 2. Check Intervals
            let sortedDates = txs.map { $0.unwrappedDate }.sorted()
            var isRegular = true
            
            for i in 0..<(sortedDates.count - 1) {
                let interval = sortedDates[i+1].timeIntervalSince(sortedDates[i])
                let days = interval / 86400
                
                // If transactions are too close (e.g. bought 2 coffees same day), it's not a sub
                if days < 6 {
                    isRegular = false
                    break
                }
            }
            
            if isRegular {
                let sample = txs.first!
                detected.append(ExpenseSubscription(
                    merchant: sample.unwrappedDesc, // Use original name for display
                    amount: sample.amount,
                    occurences: txs.count
                ))
            }
        }
        
        return detected.sorted(by: { $0.amount > $1.amount })
    }
}

// Helper Struct for passing data back from Background Thread
struct MetricsResult {
    var total: Double = 0.0
    var totalIncome: Double = 0.0
    var netSavings: Double = 0.0
    var month: Double = 0.0
    var catTotals: [String: Double] = [:]
    var pieData: [CategorySpend] = []
    var barData: [DailySpend] = []
    var forecast: Double = 0.0
    var forecastConfidence: Double = 0.0
    var forecastReason: String = ""
}

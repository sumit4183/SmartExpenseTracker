import Foundation
import SwiftUI
import Combine

struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let color: Color
}

class InsightsViewModel: ObservableObject {
    @Published var insights: [InsightItem] = []
    
    // Generate insights based on the transaction list
    func generateInsights(transactions: [Transaction]) {
        var newInsights: [InsightItem] = []
        
        // Filter for last 2 weeks (14 days)
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentTransactions = transactions.filter { $0.unwrappedDate >= twoWeeksAgo }
        
        guard !recentTransactions.isEmpty else {
            self.insights = []
            return
        }
        
        // 1. Dominant Category Insight
        // "Dining is 42% of your spend (Last 2 Weeks)"
        let totalSpend = recentTransactions.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: recentTransactions, by: { $0.unwrappedCategory })
        
        // Find the category with highest total spend
        if let topCategory = grouped.max(by: { 
            let sum1 = $0.value.reduce(0) { $0 + $1.amount }
            let sum2 = $1.value.reduce(0) { $0 + $1.amount }
            return sum1 < sum2
        }) {
            let catTotal = topCategory.value.reduce(0) { $0 + $1.amount }
            let percentage = Int((catTotal / totalSpend) * 100)
            
            if percentage > 20 { // Only show if significant
                newInsights.append(InsightItem(
                    icon: "chart.pie.fill",
                    title: "Spending Analysis",
                    message: "\(topCategory.key) accounts for \(percentage)% of your spending recently.",
                    color: .blue
                ))
            }
        }
        
        // 2. High Frequency Insight
        // "You visited Starbucks 5 times this week"
        // Group by Description (Approximate merchant matching)
        let merchantCounts = Dictionary(grouping: recentTransactions, by: { $0.unwrappedDesc })
        if let topMerchant = merchantCounts.max(by: { $0.value.count < $1.value.count }), topMerchant.value.count >= 3 {
             newInsights.append(InsightItem(
                icon: "bag.fill",
                title: "Frequent Spot",
                message: "You've visited '\(topMerchant.key)' \(topMerchant.value.count) times recently.",
                color: .orange
            ))
        }
        
        // 3. Calm Weekend Insight
        // If it's Monday, look back at weekend? For now, let's keep it simple.
        
        DispatchQueue.main.async {
            self.insights = newInsights
        }
    }
}

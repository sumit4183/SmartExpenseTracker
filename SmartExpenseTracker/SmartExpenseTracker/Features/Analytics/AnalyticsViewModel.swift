import Foundation
import CoreData
import Combine

struct MonthlySummary: Identifiable, Equatable {
    let id = UUID()
    let date: Date // e.g., representing March 2026
    var totalIncome: Double = 0.0
    var totalSpend: Double = 0.0
    
    var netBalance: Double {
        totalIncome - totalSpend
    }
    
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

class AnalyticsViewModel: ObservableObject {
    @Published var monthlySummaries: [MonthlySummary] = []
    @Published var filteredMonthlySummaries: [MonthlySummary] = []
    @Published var availableYears: [Int] = []
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date()) {
        didSet {
            filterDataByYear()
        }
    }
    
    @Published var selectedMonth: MonthlySummary?
    @Published var selectedMonthCategories: [CategorySpend] = []
    
    private var allTransactions: [Transaction] = []
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchData()
    }
    
    func fetchData() {
        let request = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            allTransactions = try viewContext.fetch(request)
            generateMonthlySummaries()
            extractAvailableYears()
            filterDataByYear()
        } catch {
            print("Failed to fetch data for Analytics: \(error)")
        }
    }
    
    private func generateMonthlySummaries() {
        let calendar = Calendar.current
        var dict: [Date: MonthlySummary] = [:]
        
        for t in allTransactions {
            // Group by start of month
            let components = calendar.dateComponents([.year, .month], from: t.unwrappedDate)
            guard let monthDate = calendar.date(from: components) else { continue }
            
            var summary = dict[monthDate] ?? MonthlySummary(date: monthDate)
            
            if t.typeEnum == .expense {
                summary.totalSpend += t.unwrappedBaseAmount
            } else {
                summary.totalIncome += t.unwrappedBaseAmount
            }
            
            dict[monthDate] = summary
        }
        
        // Sort descending by date
        self.monthlySummaries = dict.values.sorted { $0.date > $1.date }
    }
    
    private func extractAvailableYears() {
        let calendar = Calendar.current
        var years = Set<Int>()
        for t in allTransactions {
            years.insert(calendar.component(.year, from: t.unwrappedDate))
        }
        
        let sortedYears = Array(years).sorted(by: >)
        self.availableYears = sortedYears.isEmpty ? [calendar.component(.year, from: Date())] : sortedYears
        
        // Ensure selected year is valid
        if !self.availableYears.contains(selectedYear) && !self.availableYears.isEmpty {
            selectedYear = self.availableYears.first!
        }
    }
    
    private func filterDataByYear() {
        let calendar = Calendar.current
        self.filteredMonthlySummaries = self.monthlySummaries.filter {
            calendar.component(.year, from: $0.date) == selectedYear
        }
        
        // Auto-select latest month in the filtered year if available
        if let first = self.filteredMonthlySummaries.first {
            self.selectMonth(first)
        } else {
            self.selectedMonth = nil
            self.selectedMonthCategories = []
        }
    }
    
    func selectMonth(_ summary: MonthlySummary) {
        self.selectedMonth = summary
        
        let calendar = Calendar.current
        let monthTransactions = allTransactions.filter { 
            calendar.isDate($0.unwrappedDate, equalTo: summary.date, toGranularity: .month) && $0.typeEnum == .expense
        }
        
        var catTotals: [String: Double] = [:]
        for t in monthTransactions {
            catTotals[t.unwrappedCategory, default: 0] += t.unwrappedBaseAmount
        }
        
        self.selectedMonthCategories = catTotals.map { key, value in
            CategorySpend(category: key, amount: value)
        }.sorted(by: { $0.amount > $1.amount })
    }
}

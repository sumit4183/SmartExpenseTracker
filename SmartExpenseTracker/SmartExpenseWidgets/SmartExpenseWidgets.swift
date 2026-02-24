import WidgetKit
import SwiftUI
import CoreData

struct SmartExpenseEntry: TimelineEntry {
    let date: Date
    let recentTransactions: [Transaction]
    let netBalance: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SmartExpenseEntry {
        SmartExpenseEntry(date: Date(), recentTransactions: [], netBalance: 1250.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmartExpenseEntry) -> ()) {
        let (transactions, balance) = fetchWidgetData()
        let entry = SmartExpenseEntry(date: Date(), recentTransactions: transactions, netBalance: balance)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmartExpenseEntry>) -> ()) {
        let (transactions, balance) = fetchWidgetData()
        let entry = SmartExpenseEntry(date: Date(), recentTransactions: transactions, netBalance: balance)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchWidgetData() -> ([Transaction], Double) {
        // Warning: This requires the App Group and target memberships to be configured!
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Transaction> = NSFetchRequest<Transaction>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 3
        
        do {
            let recent = try context.fetch(request)
            
            // Calculate rough net balance for the widget
            let balanceRequest: NSFetchRequest<Transaction> = NSFetchRequest<Transaction>(entityName: "Transaction")
            let all = try context.fetch(balanceRequest)
            let income = all.filter { $0.typeEnum == .income }.reduce(0) { $0 + $1.amount }
            let expenses = all.filter { $0.typeEnum == .expense }.reduce(0) { $0 + $1.amount }
            
            return (recent, income - expenses)
        } catch {
            return ([], 0)
        }
    }
}

struct SmartExpenseWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Net Balance")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(entry.netBalance, format: .currency(code: "USD"))
                .font(.headline)
                .bold()
                .padding(.bottom, 2)
            
            Divider()
            
            if entry.recentTransactions.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(entry.recentTransactions.prefix(2), id: \.id) { transaction in
                    HStack {
                        Image(systemName: transaction.categoryIcon)
                            .foregroundColor(transaction.categoryColor)
                        Text(transaction.unwrappedDesc)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(transaction.amount, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                }
            }
        }
    }
}

struct SmartExpenseWidgets: Widget {
    let kind: String = "SmartExpenseWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SmartExpenseWidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SmartExpenseWidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Smart Expense")
        .description("Track your recent spending and balance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

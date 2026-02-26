import WidgetKit
import SwiftUI
import CoreData
import AppIntents

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
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            LockScreenWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Net Balance)
struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.blue)
                Text("Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.netBalance, format: .currency(code: "USD"))
                .font(.title2)
                .bold()
                .minimumScaleFactor(0.8)
                .foregroundStyle(entry.netBalance >= 0 ? Color.primary : Color.red)
            
            Spacer()
            
            if let latest = entry.recentTransactions.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: latest.categoryIcon)
                            .foregroundStyle(latest.categoryColor)
                            .font(.caption2)
                        Text(latest.unwrappedDesc)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No recent spending")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Medium Widget (Recent List)
struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    @AppStorage("widgetShortcut1Amount", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Amount: Double = 5.0
    @AppStorage("widgetShortcut1Merchant", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Merchant: String = "Coffee"
    @AppStorage("widgetShortcut1Category", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Category: String = "Food & Drink"
    
    @AppStorage("widgetShortcut2Amount", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Amount: Double = 20.0
    @AppStorage("widgetShortcut2Merchant", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Merchant: String = "Transport"
    @AppStorage("widgetShortcut2Category", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Category: String = "Transport"
    
    var body: some View {
        HStack {
            // Left Side: Balance
            VStack(alignment: .leading) {
                Text("Net Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.netBalance, format: .currency(code: "USD"))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(entry.netBalance >= 0 ? Color.primary : Color.red)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Right Side: Recent Transactions & Quick Log
            VStack(alignment: .leading, spacing: 8) {
                if entry.recentTransactions.isEmpty {
                    Text("No recent transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(entry.recentTransactions.prefix(2), id: \.id) { transaction in
                        HStack {
                            Image(systemName: transaction.categoryIcon)
                                .foregroundColor(transaction.categoryColor)
                                .font(.caption2)
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
                
                Spacer()
                
                // Interactive Quick Log Buttons (iOS 17+)
                if #available(iOS 17.0, *) {
                    HStack {
                        Button(intent: QuickLogIntent(amount: shortcut1Amount, merchant: shortcut1Merchant, category: shortcut1Category)) {
                            HStack {
                                Image(systemName: Transaction.icon(for: shortcut1Category))
                                Text("+\(shortcut1Amount, format: .currency(code: "USD"))")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Transaction.color(for: shortcut1Category).opacity(0.1), in: Capsule())
                            .foregroundStyle(Transaction.color(for: shortcut1Category))
                        }
                        .buttonStyle(.plain) // Prevents the whole widget from being tap-highlighted
                        
                        Button(intent: QuickLogIntent(amount: shortcut2Amount, merchant: shortcut2Merchant, category: shortcut2Category)) {
                            HStack {
                                Image(systemName: Transaction.icon(for: shortcut2Category))
                                Text("+\(shortcut2Amount, format: .currency(code: "USD"))")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Transaction.color(for: shortcut2Category).opacity(0.1), in: Capsule())
                            .foregroundStyle(Transaction.color(for: shortcut2Category))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
    }
}

// MARK: - Lock Screen Widget (Accessory Rectangular)
struct LockScreenWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "chart.pie.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Net Balance")
                    .font(.caption2)
                Text(entry.netBalance, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .bold()
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
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

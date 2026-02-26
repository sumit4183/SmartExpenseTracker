import SwiftUI
import CoreData
import WidgetKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = true
    @State private var csvFile: URL? = nil
    @State private var showResetAlert = false
    
    // Widget Customization (Shared App Group)
    private let appGroupStore = UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")
    
    @AppStorage("widgetShortcut1Amount", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Amount: Double = 5.0
    @AppStorage("widgetShortcut1Merchant", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Merchant: String = "Coffee"
    @AppStorage("widgetShortcut1Category", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut1Category: String = "Food & Drink"
    
    @AppStorage("widgetShortcut2Amount", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Amount: Double = 20.0
    @AppStorage("widgetShortcut2Merchant", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Merchant: String = "Transport"
    @AppStorage("widgetShortcut2Category", store: UserDefaults(suiteName: "group.com.sumit4183.SmartExpenseTracker")) private var shortcut2Category: String = "Transport"
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Data Management")) {
                    if let fileURL = csvFile {
                        ShareLink(item: fileURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                Text("Export Data (CSV)")
                                    .foregroundColor(.primary)
                            }
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Preparing export...")
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("Widget Shortcuts (iOS 17+)")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut 1 (Blue Button)")
                            .font(.headline)
                        HStack {
                            TextField("Merchant", text: $shortcut1Merchant)
                                .textFieldStyle(.roundedBorder)
                            TextField("Amount", value: $shortcut1Amount, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        Picker("Category", selection: $shortcut1Category) {
                            ForEach(["Food & Drink", "Groceries", "Transport", "Shopping", "Entertainment", "Health", "Bills", "Other"], id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut 2 (Green Button)")
                            .font(.headline)
                        HStack {
                            TextField("Merchant", text: $shortcut2Merchant)
                                .textFieldStyle(.roundedBorder)
                            TextField("Amount", value: $shortcut2Amount, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        Picker("Category", selection: $shortcut2Category) {
                            ForEach(["Food & Drink", "Groceries", "Transport", "Shopping", "Entertainment", "Health", "Bills", "Other"], id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Reset App Data")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                exportCSV()
            }
            .alert("Reset Everything?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will delete all transactions and reset your budget. You cannot undo this.")
            }
            .onChange(of: shortcut1Amount) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: shortcut1Merchant) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: shortcut1Category) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: shortcut2Amount) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: shortcut2Merchant) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: shortcut2Category) { WidgetCenter.shared.reloadAllTimelines() }
        }
    }
    
    private func resetApp() {
        // 1. Wipe Core Data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Transaction.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Error resetting data: \(error)")
        }
        
        // 2. Reset Onboarding
        hasOnboarded = false
    }
    
    private func exportCSV() {
        // Run in background to avoid hitch
        DispatchQueue.global(qos: .userInitiated).async {
            let csvString = CSVManager.generateCSV(context: viewContext)
            let fileName = "MyExpenses.csv"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: path, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.csvFile = path
                }
            } catch {
                print("Failed to save CSV: \(error)")
            }
        }
    }
}

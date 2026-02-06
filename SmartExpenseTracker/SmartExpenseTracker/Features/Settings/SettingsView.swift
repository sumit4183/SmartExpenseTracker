import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = true
    @State private var csvFile: URL? = nil
    @State private var showResetAlert = false
    
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

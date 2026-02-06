import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var csvFile: URL? = nil
    
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
        }
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

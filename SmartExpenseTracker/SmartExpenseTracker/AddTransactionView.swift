import SwiftUI
import CoreData

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddTransactionViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: AddTransactionViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Amount Section
                Section {
                    TextField("0.00", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                } header: {
                    Text("Amount")
                }
                
                // MARK: - Details Section
                Section {
                    TextField("Description (e.g., Starbucks)", text: $viewModel.description)
                    
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Details")
                } footer: {
                    if !viewModel.description.isEmpty {
                        Text("Category automatically suggested by AI")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveTransaction() {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(viewModel.amount.isEmpty || viewModel.description.isEmpty)
                }
            }
            .alert("Unusual Spend Detected", isPresented: $viewModel.showAnomalyAlert) {
                Button("Save Anyway", role: .destructive) {
                    viewModel.confirmAnomalySave()
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Check Amount", role: .cancel) { }
            } message: {
                Text(viewModel.anomalyMessage)
            }
        }
    }
}

#Preview {
    AddTransactionView(context: PersistenceController.preview.container.viewContext)
}

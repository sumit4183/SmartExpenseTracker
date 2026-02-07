import SwiftUI
import CoreData

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddTransactionViewModel
    private var isEditing: Bool
    
    init(context: NSManagedObjectContext, transactionToEdit: Transaction? = nil) {
        _viewModel = StateObject(wrappedValue: AddTransactionViewModel(context: context, transaction: transactionToEdit))
        self.isEditing = (transactionToEdit != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Amount Section
                Section {
                    Picker("Type", selection: $viewModel.type) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    
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
                    if !viewModel.description.isEmpty && !isEditing {
                        Text("Category automatically suggested by AI")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
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

import SwiftUI
import CoreData

struct TransactionListView: View {
    @StateObject private var viewModel: TransactionListViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TransactionListViewModel(context: context))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.sectionHeaders, id: \.self) { sectionDate in
                Section(header: Text(sectionDate)) {
                    ForEach(viewModel.transactionSections[sectionDate] ?? []) { transaction in
                        HStack {
                            Image(systemName: transaction.categoryIcon)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(transaction.categoryColor, in: Circle())
                            
                            VStack(alignment: .leading) {
                                Text(transaction.unwrappedDesc)
                                    .fontWeight(.medium)
                                Text(transaction.unwrappedCategory)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(transaction.formattedAmount)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTransaction(at: offsets, in: sectionDate)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText)
        .navigationTitle("History")
    }
}

#Preview {
    NavigationView {
        TransactionListView(context: PersistenceController.preview.container.viewContext)
    }
}

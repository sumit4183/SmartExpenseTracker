import SwiftUI
import CoreData

struct TransactionListView: View {
    @StateObject private var viewModel: TransactionListViewModel
    @State private var transactionToEdit: Transaction?
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TransactionListViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            filterPicker
            categoryToolbar
            sortOrderToolbar
            
            // 3. Lazy List Content
            TransactionListContent(
                predicate: viewModel.currentPredicate,
                sortDescriptors: viewModel.currentSortDescriptors,
                onDelete: viewModel.deleteTransaction,
                onEdit: { transaction in
                    transactionToEdit = transaction
                }
            )
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("History")
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(context: viewModel.viewContext, transactionToEdit: transaction)
        }
    }
    
    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(TransactionListViewModel.FilterOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var categoryToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Button {
                        if viewModel.selectedCategory == category {
                            viewModel.selectedCategory = nil
                        } else {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedCategory == category ? Color.blue : Color(.systemGray6))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private var sortOrderToolbar: some View {
        HStack {
            Text("Sort by")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Sort Type
            HStack(spacing: 0) {
                Button {
                    viewModel.sortOption = (viewModel.sortOption == .lowest || viewModel.sortOption == .oldest) ? .oldest : .newest
                } label: {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .frame(width: 36, height: 28)
                        .background(viewModel.sortOption == .newest || viewModel.sortOption == .oldest ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(viewModel.sortOption == .newest || viewModel.sortOption == .oldest ? 0.1 : 0), radius: 2)
                }
                
                Button {
                    viewModel.sortOption = (viewModel.sortOption == .lowest || viewModel.sortOption == .oldest) ? .lowest : .highest
                } label: {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .frame(width: 36, height: 28)
                        .background(viewModel.sortOption == .highest || viewModel.sortOption == .lowest ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(viewModel.sortOption == .highest || viewModel.sortOption == .lowest ? 0.1 : 0), radius: 2)
                }
            }
            .padding(2)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Spacer()
            
            Text("Order by")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Order Direction
            HStack(spacing: 0) {
                Button {
                     if viewModel.sortOption == .newest { viewModel.sortOption = .oldest }
                     if viewModel.sortOption == .highest { viewModel.sortOption = .lowest }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .frame(width: 36, height: 28)
                        .background(viewModel.sortOption == .oldest || viewModel.sortOption == .lowest ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(viewModel.sortOption == .oldest || viewModel.sortOption == .lowest ? 0.1 : 0), radius: 2)
                }
                
                Button {
                    if viewModel.sortOption == .oldest { viewModel.sortOption = .newest }
                    if viewModel.sortOption == .lowest { viewModel.sortOption = .highest }
                } label: {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .frame(width: 36, height: 28)
                        .background(viewModel.sortOption == .newest || viewModel.sortOption == .highest ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(viewModel.sortOption == .newest || viewModel.sortOption == .highest ? 0.1 : 0), radius: 2)
                }
            }
            .padding(2)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
}

// Subview allowing FetchRequest to update when init params change
struct TransactionListContent: View {
    @SectionedFetchRequest<String, Transaction> private var sections: SectionedFetchResults<String, Transaction>
    var onDelete: (Transaction) -> Void
    var onEdit: (Transaction) -> Void
    
    init(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], 
         onDelete: @escaping (Transaction) -> Void,
         onEdit: @escaping (Transaction) -> Void) {
        self.onDelete = onDelete
        self.onEdit = onEdit
        _sections = SectionedFetchRequest(
            entity: Transaction.entity(),
            sectionIdentifier: \.sectionIdentifier,
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
    }
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(formatHeader(section.id))) {
                    ForEach(section) { transaction in
                        TransactionRow(transaction: transaction, onEdit: onEdit, onDelete: onDelete)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    func formatHeader(_ id: String) -> String {
        // "2023-10-27" -> "Today" or "Oct 27, 2023"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: id) else { return id }
        
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let onEdit: (Transaction) -> Void
    let onDelete: (Transaction) -> Void
    
    var body: some View {
        rowContent
            .swipeActions(edge: .leading) {
                editAction
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                deleteAction
            }
    }
    
    private var rowContent: some View {
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
                .fontWeight(transaction.typeEnum == .income ? .bold : .regular)
                .foregroundStyle(transaction.typeEnum == .income ? Color.green : Color.primary)
        }
    }
    
    private var editAction: some View {
        Button {
            onEdit(transaction)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }
    
    private var deleteAction: some View {
        Button(role: .destructive) {
            onDelete(transaction)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

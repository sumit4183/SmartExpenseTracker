import SwiftUI
import CoreData

struct TransactionListView: View {
    @StateObject private var viewModel: TransactionListViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TransactionListViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 0. Filter Pivot (All / Expense / Income)
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(TransactionListViewModel.FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // 1. Categories Toolbar
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
            
            // 2. Sort & Order Toolbar (Reference Design)
            HStack {
                Text("Sort by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Sort Type: Date vs Amount
                HStack(spacing: 0) {
                    Button {
                        // Switch to Date (preserve order)
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
                        // Switch to Amount (preserve order)
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
                
                // Order: Asc vs Desc
                HStack(spacing: 0) {
                    Button {
                        // Switch to Ascending (Oldest / Lowest)
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
                        // Switch to Descending (Newest / Highest)
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
            
            // The List
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
                                    .fontWeight(transaction.typeEnum == .income ? .bold : .regular)
                                    .foregroundStyle(transaction.typeEnum == .income ? Color.green : Color.primary)
                            }
                        }
                        .onDelete { offsets in
                            viewModel.deleteTransaction(at: offsets, in: sectionDate)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .searchable(text: $viewModel.searchText)
        .navigationTitle("History")
    }
}

#Preview {
    NavigationView {
        TransactionListView(context: PersistenceController.preview.container.viewContext)
    }
}

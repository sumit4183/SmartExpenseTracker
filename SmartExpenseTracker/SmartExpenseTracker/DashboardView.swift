import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var showAddSheet = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header Card
                    VStack(spacing: 8) {
                        Text("Total Spend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalSpend, format: .currency(code: "USD"))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        
                        Text("Forecast: $\(String(format: "%.2f", viewModel.totalSpend * 1.2)) (Est)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1), in: Capsule())
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Chart Placewolder
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 180)
                        Text("Weekly Spend Trend")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            
                            // See All Button
                            NavigationLink(destination: TransactionListView(context: viewModel.viewContext)) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing, 8)
                            
                            Button {
                                showAddSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                            HStack {
                                Image(systemName: transaction.categoryIcon)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(transaction.categoryColor, in: Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(transaction.unwrappedDesc)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(transaction.unwrappedCategory)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(transaction.formattedAmount)
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(context: viewModel.viewContext)
                    .onDisappear {
                        // Refresh data when sheet closes
                        viewModel.fetchData()
                    }
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}

#Preview {
    DashboardView(context: PersistenceController.preview.container.viewContext)
}

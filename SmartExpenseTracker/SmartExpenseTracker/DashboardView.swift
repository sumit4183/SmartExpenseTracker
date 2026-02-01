import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var insightsViewModel = InsightsViewModel()
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
                        
                        if viewModel.isLearning {
                             Text("AI Learning... (\(viewModel.learningProgress))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1), in: Capsule())
                        } else {
                            Text("Forecast: \(viewModel.predictedSpend.formatted(.currency(code: "USD")))")
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Insights Carousel (New)
                    if !insightsViewModel.insights.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(insightsViewModel.insights) { insight in
                                    InsightCard(
                                        icon: insight.icon,
                                        title: insight.title,
                                        message: insight.message,
                                        color: insight.color
                                    )
                                    .frame(width: 300) // Fixed width for carousel feel
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Fallback Chart Placeholder (if no insights yet)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(height: 120)
                            Text("Insights will appear here as you spend.")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal)
                    }
                    
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
                        // Refresh insights
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            insightsViewModel.generateInsights(transactions: viewModel.recentTransactions)
                        }
                    }
            }
        }
        .onAppear {
            viewModel.fetchData()
            // Initial insight generation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                insightsViewModel.generateInsights(transactions: viewModel.recentTransactions)
            }
        }
    }
}

#Preview {
    DashboardView(context: PersistenceController.preview.container.viewContext)
}

import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var insightsViewModel = InsightsViewModel()
    @State private var showContent = false
    @State private var showAddSheet = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header Card (Spend & Trend)
                    VStack(spacing: 8) {
                        Text("Total Spend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalSpend, format: .currency(code: "USD"))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        
                        // Sparkline Trend (Last 7 Days)
                        if !viewModel.weeklyData.isEmpty {
                            VStack(spacing: 4) {
                                SparklineView(
                                    data: viewModel.weeklyData.map { $0.amount },
                                    color: .blue,
                                    labels: viewModel.weeklyData.map { $0.dayName }
                                )
                                .frame(height: 50)
                                .padding(.horizontal, 20)
                                
                                HStack {
                                    Text("Last 7 Days (Trend)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    // Calculate Avg
                                    let total7 = viewModel.weeklyData.reduce(0) { $0 + $1.amount }
                                    let avg7 = total7 / Double(max(1, viewModel.weeklyData.count))
                                    Text("Avg: \(avg7.formatted(.currency(code: "USD")))/day")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 40)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    // MARK: - AI Forecast Pill
                    if !viewModel.isLearning {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Predicted")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                Text(viewModel.predictedSpend, format: .currency(code: "USD"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            // Confidence Chip
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.forecastConfidence > 0.8 ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                    .font(.caption2)
                                    .foregroundStyle(viewModel.forecastConfidence > 0.8 ? .green : .orange)
                                
                                Text(viewModel.forecastReason)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6), in: Capsule())
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 25)
                    } else {
                         Text("AI Learning... (\(viewModel.learningProgress))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.vertical, 8)
                    }
                    
                    // MARK: - Monthly Budget (Power Feature)
                    BudgetView(totalSpend: viewModel.currentMonthSpend, budget: $viewModel.monthlyBudget)
                        .padding(.horizontal)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    // MARK: - Recurring Subscriptions (Power Feature)
                    if !viewModel.subscriptions.isEmpty {
                        SubscriptionView(subscriptions: viewModel.subscriptions)
                            .padding(.horizontal)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 25)
                    }
                    


                    // MARK: - Spending Mix (Donut)
                    if !viewModel.categoryData.isEmpty {
                        PieChartView(data: viewModel.categoryData)
                            .padding(.horizontal)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30) // Slightly delayed offset effect
                    }

                    // MARK: - Insights Carousel
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
                                HapticManager.shared.impact(style: .medium)
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
            
            // Animate In
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
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

import SwiftUI
import CoreData

struct AnalyticsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Weekly Trend
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Trend")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !viewModel.weeklyData.isEmpty {
                            VStack(spacing: 8) {
                                SparklineView(
                                    data: viewModel.weeklyData.map { $0.amount },
                                    color: .blue,
                                    labels: viewModel.weeklyData.map { $0.dayName }
                                )
                                .frame(height: 120) // Bigger than Dashboard
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        } else {
                            Text("Not enough data yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    
                    // MARK: - Spending Mix
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spending Mix")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !viewModel.categoryData.isEmpty {
                            PieChartView(data: viewModel.categoryData)
                                .frame(height: 300)
                                .padding(.horizontal)
                        } else {
                            Text("No spending data yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
        }
    }
}

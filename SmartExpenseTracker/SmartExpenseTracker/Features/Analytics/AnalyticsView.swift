import SwiftUI
import CoreData
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var selectedMonthString: String?
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if viewModel.monthlySummaries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("No history available yet.")
                                .font(.headline)
                        }
                        .padding(.top, 100)
                    } else {
                        // MARK: - Macro Chart (Last 6 Months)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Historical Net Balance")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                // Show up to the selected year's months
                                ForEach(viewModel.filteredMonthlySummaries.prefix(12).reversed()) { summary in
                                    BarMark(
                                        x: .value("Month", summary.monthString),
                                        y: .value("Balance", summary.netBalance)
                                    )
                                    .foregroundStyle(summary.netBalance >= 0 ? Color.green.gradient : Color.red.gradient)
                                    .cornerRadius(4)
                                }
                                
                                if let selectedStr = selectedMonthString,
                                   let matchingSummary = viewModel.filteredMonthlySummaries.first(where: { $0.monthString == selectedStr }) {
                                    RuleMark(
                                        x: .value("Selected", selectedStr)
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .foregroundStyle(.gray)
                                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                                        VStack(spacing: 4) {
                                            Text(matchingSummary.monthString)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text(matchingSummary.netBalance.formatted(.currency(code: "USD")))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(matchingSummary.netBalance >= 0 ? .green : .red)
                                        }
                                        .padding(6)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                        .shadow(radius: 2, y: 1)
                                    }
                                }
                            }
                            .chartXSelection(value: $selectedMonthString)
                            .padding(.top, 40) // Prevents the tooltip annotation from clipping
                            .frame(height: 220)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Micro View (Selected Month)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Monthly Breakdown")
                                    .font(.headline)
                                Spacer()
                                
                                // Year Picker
                                if viewModel.availableYears.count > 1 {
                                    Picker("Year", selection: $viewModel.selectedYear) {
                                        ForEach(viewModel.availableYears, id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.blue)
                                }
                                
                                // Month Picker
                                if let selected = viewModel.selectedMonth {
                                    Picker("Month", selection: Binding(
                                        get: { selected.id },
                                        set: { newId in
                                            if let match = viewModel.monthlySummaries.first(where: { $0.id == newId }) {
                                                viewModel.selectMonth(match)
                                            }
                                        }
                                    )) {
                                        ForEach(viewModel.filteredMonthlySummaries) { summary in
                                            Text(summary.monthString).tag(summary.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            if let selected = viewModel.selectedMonth {
                                // Mini Stat Row
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text("Income")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(selected.totalIncome.formatted(.currency(code: "USD")))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.green)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Spend")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(selected.totalSpend.formatted(.currency(code: "USD")))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.red)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                            
                            if !viewModel.selectedMonthCategories.isEmpty {
                                PieChartView(data: viewModel.selectedMonthCategories)
                                    .frame(height: 300)
                                    .padding(.horizontal)
                            } else {
                                Text("No expenses recorded for this month.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reports")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}


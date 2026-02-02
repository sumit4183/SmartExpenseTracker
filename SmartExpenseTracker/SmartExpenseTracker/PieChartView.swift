import SwiftUI
import Charts

struct PieChartView: View {
    let data: [CategorySpend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.purple)
                Text("Spending Mix")
                    .font(.headline)
                Spacer()
            }
            
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
            } else {
                HStack {
                    // Chat
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.6), // Donut style
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 150)
                    .frame(width: 150) // Keep the pie roughly square
                    
                    Spacer()
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data.prefix(4)) { item in // Top 4 only
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.amount, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    PieChartView(data: [
        CategorySpend(category: "Food", amount: 120),
        CategorySpend(category: "Transport", amount: 45),
        CategorySpend(category: "Bills", amount: 300)
    ])
    .padding()
}

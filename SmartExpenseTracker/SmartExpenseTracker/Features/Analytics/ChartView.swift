import SwiftUI
import Charts

struct ChartView: View {
    let data: [DailySpend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Weekly Trend")
                    .font(.headline)
                Spacer()
            }
            
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 180)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Day", item.dayName),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
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
    ChartView(data: [
        DailySpend(date: Date(), amount: 50),
        DailySpend(date: Date().addingTimeInterval(-86400), amount: 120),
        DailySpend(date: Date().addingTimeInterval(-86400*2), amount: 30)
    ])
    .padding()
    .background(Color.gray.opacity(0.1))
}

import SwiftUI

struct BudgetView: View {
    let totalSpend: Double
    @Binding var budget: Double
    @State private var showEditAlert = false
    @State private var newBudgetInput = ""
    
    var progress: Double {
        guard budget > 0 else { return 0 }
        return totalSpend / budget
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                Text("Monthly Budget")
                    .font(.headline)
                Spacer()
                
                Button {
                    newBudgetInput = String(format: "%.0f", budget)
                    showEditAlert = true
                } label: {
                    Text("Edit")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1), in: Capsule())
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(progress > 1.0 ? Color.red : Color.green)
                        .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 12)
                        .animation(.spring, value: progress)
                }
            }
            .frame(height: 12)
            
            // Meta Text
            HStack {
                Text("\(totalSpend.formatted(.currency(code: "USD"))) spent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(budget.formatted(.currency(code: "USD"))) limit")
                    .font(.caption)
                    .bold()
            }
            
            if progress > 1.0 {
                Text("You are over budget!")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .bold()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("Set Monthly Budget", isPresented: $showEditAlert) {
            TextField("Amount", text: $newBudgetInput)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let newAmount = Double(newBudgetInput) {
                    budget = newAmount
                }
            }
        } message: {
            Text("Enter your spending limit for the month.")
        }
    }
}

#Preview {
    BudgetView(totalSpend: 1500, budget: .constant(2000))
        .padding()
        .background(Color.gray.opacity(0.1))
}

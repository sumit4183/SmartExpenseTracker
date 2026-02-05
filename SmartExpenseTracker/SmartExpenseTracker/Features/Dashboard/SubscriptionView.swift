import SwiftUI

struct SubscriptionView: View {
    let subscriptions: [ExpenseSubscription]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text("Recurring (Detected)")
                    .font(.headline)
                Spacer()
            }
            
            if subscriptions.isEmpty {
                Text("No recurring payments detected yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subscriptions) { sub in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "crown.fill") // Premium icon
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    Spacer()
                                    Text(sub.amount, format: .currency(code: "USD"))
                                        .bold()
                                }
                                
                                Text(sub.merchant)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text("Paid \(sub.occurences) times")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(width: 140)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
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
    SubscriptionView(subscriptions: [
        ExpenseSubscription(merchant: "Netflix", amount: 15.99, occurences: 3),
        ExpenseSubscription(merchant: "Spotify", amount: 9.99, occurences: 5)
    ])
    .padding()
}

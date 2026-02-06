import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 2000
    @State private var budgetInput: String = "2000"
    
    var body: some View {
        TabView {
            // Page 1: Welcome
            VStack(spacing: 20) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                Text("Smart Expenses")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("The expense tracker that learns from you.\nPrivate. Intelligent. Simple.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            .tag(0)
            
            // Page 2: Privacy
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.bottom, 20)
                
                Text("Privacy First")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your financial data never leaves this device.\nInternal Machine Learning runs locally to categorize your spending.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            .tag(1)
            
            // Page 3: Budget & Setup
            VStack(spacing: 30) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Set Your Goal")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    Text("What is your monthly budget?")
                        .font(.headline)
                    
                    TextField("Budget", text: $budgetInput)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                        .onChange(of: budgetInput) { _, newValue in
                            if let value = Double(newValue) {
                                monthlyBudget = value
                            }
                        }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Button {
                    withAnimation {
                        isOnboarding = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

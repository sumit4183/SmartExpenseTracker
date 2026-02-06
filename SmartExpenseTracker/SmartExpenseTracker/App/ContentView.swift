import SwiftUI
import CoreData

struct ContentView: View {
    let persistenceController = PersistenceController.shared
    @StateObject private var dashboardViewModel: DashboardViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            AnalyticsView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
            
            NavigationView {
                TransactionListView(context: persistenceController.container.viewContext)
            }
            .tabItem {
                Label("History", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}


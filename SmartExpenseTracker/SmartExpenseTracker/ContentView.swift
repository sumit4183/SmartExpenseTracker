import SwiftUI
import CoreData

struct ContentView: View {
    let persistenceController = PersistenceController.shared

    var body: some View {
        DashboardView(context: persistenceController.container.viewContext)
    }
}

#Preview {
    ContentView()
}


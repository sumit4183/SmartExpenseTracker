import SwiftUI
import CoreData

struct LearnedCategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch all overrides, sorted alphabetically by merchant name
    @FetchRequest(
        entity: CategoryOverride.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryOverride.merchantName, ascending: true)],
        animation: .default)
    private var overrides: FetchedResults<CategoryOverride>
    
    var body: some View {
        List {
            Section(header: Text("How it works").textCase(nil)) {
                Text("When you manually change a category suggested by the AI, the app remembers your preference here. You can delete these rules if you want the AI to guess again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if overrides.isEmpty {
                Text("The app hasn't learned any custom rules yet. Correct the AI when adding a transaction to teach it!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(overrides) { override in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(override.merchantName ?? "Unknown")
                                .font(.headline)
                            HStack {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(override.userPreferredCategory ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteOverrides)
            }
        }
        .navigationTitle("Learned Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteOverrides(offsets: IndexSet) {
        withAnimation {
            offsets.map { overrides[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Failed to delete learned category: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    NavigationView {
        LearnedCategoriesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

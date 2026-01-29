//
//  Persistence.swift
//  SmartExpenseTracker
//
//  Created by Sumit Patel on 1/27/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Seed some sample data for SwiftUI Previews
        let sampleCategories = ["Food", "Transport", "Rent", "Groceries", "Entertainment"]
        
        for i in 0..<10 {
            let newTransaction = Transaction(context: viewContext)
            newTransaction.id = UUID()
            newTransaction.date = Date().addingTimeInterval(Double(-i * 86400)) // Past days
            newTransaction.amount = Double.random(in: 10...150)
            newTransaction.category = sampleCategories.randomElement()
            newTransaction.desc = "Sample Transaction \(i)"
            newTransaction.isAnomaly = false
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartExpenseTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

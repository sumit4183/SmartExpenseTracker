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
        } else {
            let storeName = "SmartExpenseTracker.sqlite"
            let appGroupIdentifier = "group.com.sumit4183.SmartExpenseTracker"
            guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                fatalError("Failed to find app group container. Ensure the capability is added in Xcode.")
            }
            let storeURL = groupContainerURL.appendingPathComponent(storeName)
            
            let defaultDirectoryURL = NSPersistentContainer.defaultDirectoryURL()
            let oldStoreURL = defaultDirectoryURL.appendingPathComponent(storeName)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: oldStoreURL.path) && !fileManager.fileExists(atPath: storeURL.path) {
                print("Migrating Core Data store to App Group...")
                let extensions = ["", "-shm", "-wal"]
                do {
                    for ext in extensions {
                        let oldFile = oldStoreURL.path + ext
                        let newFile = storeURL.path + ext
                        if fileManager.fileExists(atPath: oldFile) {
                            try fileManager.moveItem(atPath: oldFile, toPath: newFile)
                        }
                    }
                    print("Migration successful.")
                } catch {
                    print("Error during migration: \(error)")
                }
            }
            
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
            container.persistentStoreDescriptions = [description]
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

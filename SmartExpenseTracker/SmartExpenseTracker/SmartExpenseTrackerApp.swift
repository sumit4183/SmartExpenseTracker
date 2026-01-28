//
//  SmartExpenseTrackerApp.swift
//  SmartExpenseTracker
//
//  Created by Sumit Patel on 1/27/26.
//

import SwiftUI
import CoreData

@main
struct SmartExpenseTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

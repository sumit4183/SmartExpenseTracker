import AppIntents

struct SmartExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTransactionIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add a transaction to \(.applicationName)",
                "Log a \(.applicationName) transaction"
            ],
            shortTitle: "Log Transaction",
            systemImageName: "dollarsign.circle"
        )
    }
}

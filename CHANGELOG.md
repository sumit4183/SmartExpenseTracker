# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-03-05

### Features
- **App Intents**: Log transactions instantly via Siri or Spotlight without opening the app.
- **Shortcuts Integration**: Built-in support for the iOS Shortcuts app ("Log an expense in Smart Expense Tracker").
- **Architecture**: Migrated database to a shared App Group container for ecosystem expansion.
- **Continuous Learning AI**: The app now dynamically learns from user corrections, bypassing standard Core ML predictions to apply personal categorization preferences.
- **Learned Categories Management**: Added a new Settings UI to view and swipe-to-delete custom AI learning rules.
- **Multi-Currency (Travel Mode)**: Added the ability to log foreign currencies with automatic base-currency conversions via a live exchange rate API.
- **Analytics Integrity**: Rewritten Dashboard engine strictly calculates insights using normalized base amounts to prevent currency contamination.

## [1.0.0] - 2026-02-06

### Initial Release 
- **Smart Transactions**: AI-powered categorization and input prediction.
- **Spending Insights**: Natural language analysis of spending habits.
- **Safety Net**: Anomaly detection for unusual transactions.
- **Dashboard**: Real-time spending visualization with "Calm Computing" design.
- **Financial Intelligence**: Monthly Budgeting, Recurring Subscription tracking, and Net Balance monitoring.
- **Data Management**: Full offline support with Core Data and Core ML.

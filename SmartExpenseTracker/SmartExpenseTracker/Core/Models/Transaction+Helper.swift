import Foundation
import CoreData
import SwiftUI

public enum TransactionType: String, CaseIterable, Identifiable {
    case expense = "expense"
    case income = "income"
    public var id: String { rawValue }
}

extension Transaction {
    
    // MARK: - Safe Accessors
    
    public var typeEnum: TransactionType {
        get {
            // Safety Check: Verify 'type' exists in the Core Data Model
            // This prevents the "valueForUndefinedKey" crash if the Attribute is missing
            if self.entity.attributesByName.keys.contains("type") {
                let typeString = self.value(forKey: "type") as? String
                return TransactionType(rawValue: typeString ?? "expense") ?? .expense
            }
            return .expense // Fallback if schema is outdated
        }
        set {
            if self.entity.attributesByName.keys.contains("type") {
                self.setValue(newValue.rawValue, forKey: "type")
            }
        }
    }
    
    public var unwrappedDesc: String {
        desc ?? "Unknown"
    }
    
    public var unwrappedCategory: String {
        category ?? "Uncategorized"
    }
    
    public var unwrappedDate: Date {
        date ?? Date()
    }
    
    public var unwrappedCurrencyCode: String {
        // Fallback to USD for legacy data or if not set
        if self.entity.attributesByName.keys.contains("currencyCode") {
            return self.value(forKey: "currencyCode") as? String ?? "USD"
        }
        return "USD"
    }
    
    public var unwrappedBaseAmount: Double {
        if self.entity.attributesByName.keys.contains("baseCurrencyAmount") {
            return self.value(forKey: "baseCurrencyAmount") as? Double ?? amount
        }
        return amount // Fallback to raw amount if no base is set
    }
    
    @objc public var sectionIdentifier: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: unwrappedDate)
    }
    
    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = unwrappedCurrencyCode // Use the transaction's specific currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    public var formattedBaseAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Our hardcoded Base Currency for Analytics
        return formatter.string(from: NSNumber(value: unwrappedBaseAmount)) ?? "$0.00"
    }
    
    // MARK: - UI Helpers
    
    var categoryColor: Color {
        switch unwrappedCategory {
        case "Food & Drink": return .orange
        case "Groceries": return .green
        case "Transport": return .blue
        case "Shopping": return .purple
        case "Utilities": return .yellow
        case "Entertainment": return .pink
        case "Travel": return .indigo
        case "Health": return .red
        case "Rent": return .brown
        case "Salary": return .mint
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch unwrappedCategory {
        case "Food & Drink": return "fork.knife"
        case "Groceries": return "carrot.fill"
        case "Transport": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Utilities": return "bolt.fill"
        case "Entertainment": return "popcorn.fill"
        case "Travel": return "airplane"
        case "Health": return "heart.text.square.fill"
        case "Rent": return "house.fill"
        case "Salary": return "dollarsign.circle.fill"
        default: return "questionmark.circle"
        }
    }
    
    // MARK: - Static Category Helpers
    
    static func color(for category: String) -> Color {
        switch category {
        case "Food & Drink": return .orange
        case "Groceries": return .green
        case "Transport": return .blue
        case "Shopping": return .purple
        case "Utilities": return .yellow
        case "Entertainment": return .pink
        case "Travel": return .indigo
        case "Health": return .red
        case "Rent": return .brown
        case "Salary": return .mint
        default: return .gray
        }
    }
    
    static func icon(for category: String) -> String {
        switch category {
        case "Food & Drink": return "fork.knife"
        case "Groceries": return "carrot.fill"
        case "Transport": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Utilities": return "bolt.fill"
        case "Entertainment": return "popcorn.fill"
        case "Travel": return "airplane"
        case "Health": return "heart.text.square.fill"
        case "Rent": return "house.fill"
        case "Salary": return "dollarsign.circle.fill"
        default: return "questionmark.circle"
        }
    }
}

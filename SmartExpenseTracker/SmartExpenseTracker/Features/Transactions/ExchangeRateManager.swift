import Foundation
import Combine

class ExchangeRateManager: ObservableObject {
    static let shared = ExchangeRateManager()
    
    @Published var rates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    
    // We use a free, undocumented public API for demonstration
    // In a real app, you would use a paid service like Fixer.io or OpenExchangeRates
    private let apiUrl = "https://api.exchangerate-api.com/v4/latest/USD"
    private let cacheKeyRates = "cachedExchangeRates"
    private let cacheKeyDate = "cachedExchangeRatesDate"
    
    // Most common currencies for the UI picker
    let supportedCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR"]
    
    init() {
        loadCachedRates()
        fetchRates()
    }
    
    func fetchRates() {
        // Only fetch if we don't have rates or they are older than 24 hours
        if let last = lastUpdated, Date().timeIntervalSince(last) < 86400 {
            return
        }
        
        guard let url = URL(string: apiUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("ExchangeRateManager Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let fetchedRates = json["rates"] as? [String: Double] {
                    DispatchQueue.main.async {
                        self?.rates = fetchedRates
                        self?.lastUpdated = Date()
                        self?.saveRatesToCache()
                    }
                }
            } catch {
                print("ExchangeRateManager JSON Error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - Conversion Logic
    
    /// Converts a foreign amount back to the Base Currency (USD)
    func convertToBase(amount: Double, from currency: String) -> Double {
        // If it's already the base currency, no conversion needed
        if currency == "USD" { return amount }
        
        // Find the exchange rate for that currency vs USD
        guard let rate = rates[currency] else {
            // If we have no network and no cache, fallback to 1:1 to prevent data loss
            return amount
        }
        
        // API gives us USD -> Foreign.
        // To get Foreign -> USD, we divide.
        // E.g. If USD -> EUR is 0.9. A 10 EUR expense = 10 / 0.9 = $11.11 USD base.
        return amount / rate
    }
    
    // MARK: - Caching
    
    private func saveRatesToCache() {
        UserDefaults.standard.set(rates, forKey: cacheKeyRates)
        if let lastUpdated = lastUpdated {
            UserDefaults.standard.set(lastUpdated, forKey: cacheKeyDate)
        }
    }
    
    private func loadCachedRates() {
        if let cachedRates = UserDefaults.standard.dictionary(forKey: cacheKeyRates) as? [String: Double] {
            self.rates = cachedRates
        }
        self.lastUpdated = UserDefaults.standard.object(forKey: cacheKeyDate) as? Date
    }
}

import Foundation
import SwiftData

final class StatsService {
    static let shared = StatsService()
    
    private init() {}
    
    struct YearlySpend: Identifiable {
        let id = UUID()
        let year: Int
        let amount: Double
    }
    
    func calculateTotalSpend(items: [Item]) -> Double {
        items.reduce(0) { $0 + (($1.price ?? 0) * Double($1.quantity)) }
    }
    
    func calculateMonthlySpend(items: [Item]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return items.filter {
            let month = calendar.component(.month, from: $0.purchaseDate)
            let year = calendar.component(.year, from: $0.purchaseDate)
            return month == currentMonth && year == currentYear
        }.reduce(0) { $0 + (($1.price ?? 0) * Double($1.quantity)) }
    }
    
    func calculateTotalQuantity(items: [Item]) -> Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    func calculateYearlyHistory(items: [Item]) -> [YearlySpend] {
        let calendar = Calendar.current
        var yearlyDict: [Int: Double] = [:]
        
        for item in items {
            let year = calendar.component(.year, from: item.purchaseDate)
            let spend = (item.price ?? 0) * Double(item.quantity)
            yearlyDict[year, default: 0] += spend
        }
        
        return yearlyDict.map { YearlySpend(year: $0.key, amount: $0.value) }
            .sorted { $0.year > $1.year }
    }
}

import Foundation
import SwiftData

@MainActor
final class SuggestionService {
    static let shared = SuggestionService()
    
    private init() {}
    
    func fetchFrequentIPs(in modelContext: ModelContext, limit: Int = 5) -> [String] {
        let descriptor = FetchDescriptor<Item>()
        guard let items = try? modelContext.fetch(descriptor) else { return [] }
        
        let counts = items.reduce(into: [String: Int]()) { counts, item in
            let ip = item.ipName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !ip.isEmpty {
                counts[ip, default: 0] += 1
            }
        }
        
        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    func fetchFrequentBrands(in modelContext: ModelContext, limit: Int = 5) -> [String] {
        let descriptor = FetchDescriptor<Item>()
        guard let items = try? modelContext.fetch(descriptor) else { return [] }
        
        let counts = items.reduce(into: [String: Int]()) { counts, item in
            let brand = item.brand.trimmingCharacters(in: .whitespacesAndNewlines)
            if !brand.isEmpty {
                counts[brand, default: 0] += 1
            }
        }
        
        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}

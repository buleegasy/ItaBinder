import Foundation
import SwiftData

struct IPGroup: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let items: [Item]
    
    var representativeImageID: String? {
        items.first?.coverImageID ?? items.first?.imageIDs.first
    }
    
    // Manual Hashable to avoid issues with @Model Item array
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: IPGroup, rhs: IPGroup) -> Bool {
        lhs.name == rhs.name
    }
}

@Observable
final class CollectionsViewModel {
    private var modelContext: ModelContext
    
    var groups: [IPGroup] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchCollections()
    }
    
    func fetchCollections() {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            let items = try modelContext.fetch(descriptor)
            
            // Group by ipName
            let groupedDict = Dictionary(grouping: items) { item in
                item.ipName.isEmpty ? "其他" : item.ipName
            }
            
            // Map to IPGroup and sort alphabetically
            groups = groupedDict.map { name, items in
                IPGroup(name: name, items: items)
            }.sorted { $0.name < $1.name }
            
            // Ensure "其他" is at the end if it exists
            if let otherIndex = groups.firstIndex(where: { $0.name == "其他" }) {
                let otherGroup = groups.remove(at: otherIndex)
                groups.append(otherGroup)
            }
        } catch {
            print("Failed to fetch items for grouping: \(error)")
        }
    }
}

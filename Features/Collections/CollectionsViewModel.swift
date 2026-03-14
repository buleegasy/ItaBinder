import Foundation
import SwiftData

@Observable
final class CollectionsViewModel {
    private var modelContext: ModelContext
    
    var collections: [Collection] = []
    var searchText: String = ""
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchCollections()
    }
    
    func fetchCollections() {
        let descriptor = FetchDescriptor<Collection>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            collections = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch collections: \(error)")
        }
    }
    
    func addCollection(name: String) {
        let newCollection = Collection(name: name)
        modelContext.insert(newCollection)
        fetchCollections()
    }
    
    func deleteCollections(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(collections[index])
        }
        fetchCollections()
    }
}

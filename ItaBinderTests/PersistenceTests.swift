import XCTest
import SwiftData
@testable import ItaBinder

final class PersistenceTests: XCTestCase {
    
    @MainActor
    func testModelCreation() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Item.self, Collection.self, Tag.self, configurations: config)
        let context = container.mainContext
        
        // Create Item
        let item = Item(title: "Test Badge", rarity: "Super Rare")
        context.insert(item)
        
        // Create Collection
        let collection = Collection(name: "Summer Vault")
        context.insert(collection)
        item.collection = collection
        
        // Create Tag
        let tag = Tag(name: "Badge")
        context.insert(tag)
        item.tags?.append(tag)
        
        try context.save()
        
        // Verify
        let fetchDescriptor = FetchDescriptor<Item>()
        let items = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Test Badge")
        XCTAssertEqual(items.first?.collection?.name, "Summer Vault")
        XCTAssertEqual(items.first?.tags?.count, 1)
    }
}

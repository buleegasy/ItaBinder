import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String = "New Item"
    var rarity: String = "Common"
    var createdAt: Date = Date()
    var thumbnailPath: String?
    var originalImagePath: String?
    
    /// Stored as data for CloudKit asset synchronization
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    var collection: Collection?
    
    @Relationship(inverse: \Tag.items)
    var tags: [Tag]?
    
    @Relationship(deleteRule: .cascade, inverse: \AssetMetadata.item)
    var assetMetadata: AssetMetadata?
    
    init(
        id: UUID = UUID(),
        title: String = "New Item",
        rarity: String = "Common",
        createdAt: Date = Date(),
        thumbnailPath: String? = nil,
        originalImagePath: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.rarity = rarity
        self.createdAt = createdAt
        self.thumbnailPath = thumbnailPath
        self.originalImagePath = originalImagePath
        self.thumbnailData = thumbnailData
        self.tags = []
    }
}
```

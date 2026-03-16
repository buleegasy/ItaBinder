import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String = "New Item"
    var ipName: String = ""
    var price: Double?
    var currency: String = "CNY"
    var quantity: Int = 1
    var brand: String = ""
    var purchaseDate: Date = Date()
    var holdingStatus: String = "已持有" // 待发货, 已发货, 已持有
    var notes: String = ""
    var createdAt: Date = Date()
    
    /// List of image asset IDs associated with this item
    var imageIDs: [String] = []
    
    /// The ID of the image used as the cover
    var coverImageID: String?
    
    /// Stored as data for CloudKit asset synchronization (usually of the cover image)
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    var collection: Collection?
    
    @Relationship(inverse: \Tag.items)
    var tags: [Tag]?
    
    @Relationship(deleteRule: .cascade, inverse: \AssetMetadata.item)
    var assetMetadata: AssetMetadata?
    
    init(
        id: UUID = UUID(),
        title: String = "New Item",
        ipName: String = "",
        price: Double? = nil,
        currency: String = "CNY",
        quantity: Int = 1,
        brand: String = "",
        purchaseDate: Date = Date(),
        holdingStatus: String = "已持有",
        notes: String = "",
        createdAt: Date = Date(),
        imageIDs: [String] = [],
        coverImageID: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.ipName = ipName
        self.price = price
        self.currency = currency
        self.quantity = quantity
        self.brand = brand
        self.purchaseDate = purchaseDate
        self.holdingStatus = holdingStatus
        self.notes = notes
        self.createdAt = createdAt
        self.imageIDs = imageIDs
        self.coverImageID = coverImageID
        self.thumbnailData = thumbnailData
        self.tags = []
    }
}

import Foundation
import SwiftData

@Model
final class AssetMetadata {
    @Attribute(.unique) var id: UUID
    var fileSize: Int64
    var width: Int
    var height: Int
    var format: String
    
    var item: Item?
    
    init(
        id: UUID = UUID(),
        fileSize: Int64 = 0,
        width: Int = 0,
        height: Int = 0,
        format: String = "unknown"
    ) {
        self.id = id
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.format = format
    }
}

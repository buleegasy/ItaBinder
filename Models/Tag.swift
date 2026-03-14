import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    
    var items: [Item]?
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.items = []
    }
}

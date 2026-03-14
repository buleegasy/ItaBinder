import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    let collection: Collection
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ItemGridView(items: collection.items ?? [])
            .navigationTitle(collection.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addItem) {
                        Image(systemName: "plus")
                    }
                }
            }
    }
    
    private func addItem() {
        let newItem = Item(title: "New Goods (\(Int.random(in: 1...100)))", rarity: ["Common", "Rare", "SR", "UR"].randomElement()!)
        newItem.collection = collection
        modelContext.insert(newItem)
    }
}

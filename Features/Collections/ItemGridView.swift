import SwiftUI
import SwiftData

struct ItemGridView: View {
    var items: [Item]
    var onScrolledToBottom: (() -> Void)? = nil
    
    // Responsive grid layout: 2 columns on small screens, 3+ on larger ones
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // Check for infinite scrolling trigger
                        if item == items.last {
                            onScrolledToBottom?()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
    }
}

#Preview {
    NavigationStack {
        ItemGridView(items: [
            Item(title: "Miku Pin", rarity: "UR"),
            Item(title: "Rei Figure", rarity: "SR"),
            Item(title: "Eva Badge", rarity: "Common")
        ])
    }
}

import SwiftUI
import SwiftData

struct ItemGridView: View {
    var items: [Item]
    var onScrolledToBottom: (() -> Void)? = nil
    
    @Environment(MainNavigationState.self) private var navState
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                // Left Column
                LazyVStack(spacing: 16) {
                    ForEach(leftColumnItems) { item in
                        itemCell(for: item)
                    }
                }
                
                // Right Column
                LazyVStack(spacing: 16) {
                    ForEach(rightColumnItems) { item in
                        itemCell(for: item)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
    }
    
    // Computed columns for simple waterfall
    private var leftColumnItems: [Item] {
        items.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
    }
    
    private var rightColumnItems: [Item] {
        items.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
    }
    
    @ViewBuilder
    private func itemCell(for item: Item) -> some View {
        if navState.isEditMode {
            ItemCard(item: item)
                .onTapGesture {
                    toggleSelection(item: item)
                }
                .onAppear {
                    checkScroll(item: item)
                }
        } else {
            NavigationLink(value: item) {
                ItemCard(item: item)
            }
            .buttonStyle(.plain)
            .onAppear {
                checkScroll(item: item)
            }
        }
    }
    
    private func toggleSelection(item: Item) {
        HapticManager.shared.impact(.light)
        if navState.selectedItemIDs.contains(item.id) {
            navState.selectedItemIDs.remove(item.id)
        } else {
            navState.selectedItemIDs.insert(item.id)
        }
    }
    
    private func checkScroll(item: Item) {
        if item == items.last {
            onScrolledToBottom?()
        }
    }

}

#Preview {
    NavigationStack {
        ItemGridView(items: [
            Item(title: "初音未来 挂件", ipName: "Vocaloid", price: 35.0, quantity: 2),
            Item(title: "绫波丽 手办", ipName: "新世纪福音战士", price: 299.0, quantity: 1, holdingStatus: "待发货"),
            Item(title: "真希波 徽章", ipName: "新世纪福音战士", price: 15.0, quantity: 5)
        ])
    }
}

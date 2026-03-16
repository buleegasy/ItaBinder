import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    let collection: Collection
    @Environment(\.modelContext) private var modelContext
    @Environment(MainNavigationState.self) private var navState
    
    var body: some View {
        ItemGridView(items: collection.items ?? [])
            .navigationTitle(collection.name)
            .onAppear {
                navState.isTabBarVisible = false
            }
            .onDisappear {
                navState.isTabBarVisible = true
            }
    }
}

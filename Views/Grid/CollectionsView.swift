import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CollectionsViewModel?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Custom Header instead of navigationTitle
                    Text("按作品分类")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if let groups = viewModel?.groups {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(groups) { group in
                                NavigationLink(value: group) {
                                    IPCategoryButton(group: group)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: IPGroup.self) { group in
                IPDetailView(group: group)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = CollectionsViewModel(modelContext: modelContext)
                }
                viewModel?.fetchCollections()
            }
        }
    }
}

struct IPCategoryButton: View {
    let group: IPGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let imageID = group.representativeImageID {
                    AsyncDisplayImage(itemID: imageID)
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.purple.opacity(0.1)
                    Image(systemName: "folder.fill")
                        .foregroundStyle(Color.purple)
                        .font(.title3)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(group.items.count) 件")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct IPDetailView: View {
    let group: IPGroup
    @Environment(MainNavigationState.self) private var navState
    
    var body: some View {
        ItemGridView(items: group.items)
            .navigationTitle(group.name)
            .onAppear {
                navState.isTabBarVisible = false
            }
            .onDisappear {
                navState.isTabBarVisible = true
            }
    }
}

#Preview {
    CollectionsView()
        .modelContainer(for: Collection.self, inMemory: true)
}

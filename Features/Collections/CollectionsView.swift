import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CollectionsViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                if let viewModel = viewModel {
                    ForEach(viewModel.collections) { collection in
                        NavigationLink(value: collection) {
                            HStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor.gradient)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(collection.name)
                                        .font(.headline)
                                    Text("\(collection.items?.count ?? 0) items")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: viewModel.deleteCollections)
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addCollection) {
                        Label("Add Collection", systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Collection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = CollectionsViewModel(modelContext: modelContext)
                }
                viewModel?.fetchCollections()
            }
        }
    }
    
    private func addCollection() {
        withAnimation {
            viewModel?.addCollection(name: "New Collection")
        }
    }
}

#Preview {
    CollectionsView()
        .modelContainer(for: Collection.self, inMemory: true)
}

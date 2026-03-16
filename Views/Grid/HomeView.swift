import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Item.title) private var allItems: [Item]
    
    @Environment(MainNavigationState.self) private var navState
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPosterExport = false
    
    var body: some View {
        @Bindable var navState = navState
        NavigationStack {
            ZStack(alignment: .bottom) {
                ItemGridView(items: allItems)
                    .navigationTitle("我的展柜")
                    .background(DynamicGlassBackground())
                    .overlay {
                        if allItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 48))
                                    .foregroundColor(.itabinderGreen.opacity(0.5))
                                Text("展柜空空如也，快去导入心爱的谷子吧~")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(navState.isEditMode ? "取消" : "选择") {
                                HapticManager.shared.impact(.light)
                                withAnimation {
                                    navState.isEditMode.toggle()
                                    if !navState.isEditMode {
                                        navState.selectedItemIDs.removeAll()
                                    }
                                }
                            }
                        }
                    }
                
                // Batch Action Bar
                if navState.isEditMode && !navState.selectedItemIDs.isEmpty {
                    VStack {
                        HStack(spacing: 12) {
                            Text("已选择 \(navState.selectedItemIDs.count) 件")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Generate Poster Button
                            Button {
                                HapticManager.shared.impact(.medium)
                                showPosterExport = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                    Text("生成海报")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.itabinderGreen)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            
                            // Delete Button
                            Button(role: .destructive) {
                                HapticManager.shared.notification(.warning)
                                deleteSelectedItems()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("删除")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showPosterExport) {
            let selectedItems = allItems.filter { navState.selectedItemIDs.contains($0.id) }
            PosterExportView(selectedItems: selectedItems)
        }
    }
    
    private func deleteSelectedItems() {
        let selectedIDs = navState.selectedItemIDs
        for item in allItems {
            if selectedIDs.contains(item.id) {
                for imageID in item.imageIDs {
                    ImageStorageManager.shared.deleteFolder(for: imageID)
                }
                modelContext.delete(item)
            }
        }
        
        try? modelContext.save()
        withAnimation {
            navState.isEditMode = false
            navState.selectedItemIDs.removeAll()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}

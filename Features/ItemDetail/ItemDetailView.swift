import SwiftUI

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @State private var isEditingTitle = false
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Section
                AsyncDisplayImage(itemID: item.id.uuidString)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                
                // Content Section
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Rarity
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditingTitle {
                            TextField("Item Title", text: $item.title)
                                .font(.title.bold())
                                .textFieldStyle(.plain)
                                .focused($isTitleFocused)
                                .onSubmit { isEditingTitle = false }
                        } else {
                            Text(item.title)
                                .font(.title.bold())
                                .onTapGesture {
                                    isEditingTitle = true
                                    isTitleFocused = true
                                }
                        }
                        
                        rarityBadge
                    }
                    
                    Divider()
                    
                    // Tags Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tags")
                            .font(.headline)
                        
                        if let tags = item.tags, !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags) { tag in
                                    Text(tag.name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        } else {
                            Text("No tags added")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Metadata Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Information")
                            .font(.headline)
                        
                        Group {
                            InfoRow(label: "Created", value: item.createdAt.formatted(date: .long, time: .shortened))
                            if let metadata = item.assetMetadata {
                                InfoRow(label: "Resolution", value: "\(metadata.width) x \(metadata.height)")
                                InfoRow(label: "File Size", value: ByteCountFormatter.string(fromByteCount: metadata.fileSize, countStyle: .file))
                            }
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditingTitle ? "Done" : "Edit") {
                    isEditingTitle.toggle()
                    if isEditingTitle { isTitleFocused = true }
                }
            }
        }
    }
    
    private var rarityBadge: some View {
        Text(item.rarity)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(rarityColor.opacity(0.15))
            .foregroundColor(rarityColor)
            .clipShape(Capsule())
    }
    
    private var rarityColor: Color {
        switch item.rarity.lowercased() {
        case "super rare", "sr": return .orange
        case "ultra rare", "ur": return .purple
        case "rare", "r": return .blue
        default: return .secondary
        }
    }
}

// MARK: - Helpers

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

/// A simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewProposal, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewProposal, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.offsets[index].x, y: bounds.minY + result.offsets[index].y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewProposal, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
            totalWidth = max(totalWidth, currentX)
        }
        
        return (CGSize(width: totalWidth, height: currentY + maxRowHeight), offsets)
    }
}

import SwiftUI

struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncThumbnailImage(itemID: item.id.uuidString)
                .aspectRatio(1, contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.rarity)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(rarityColor.opacity(0.1))
                    .foregroundColor(rarityColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
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

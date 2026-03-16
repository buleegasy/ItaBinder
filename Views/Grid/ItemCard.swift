import SwiftUI

struct ItemCard: View {
    let item: Item
    
    @Environment(MainNavigationState.self) private var navState
    
    var body: some View {
        let isSelected = navState.selectedItemIDs.contains(item.id)
        
        VStack(alignment: .leading, spacing: 10) {
            // Image Area
            ZStack(alignment: .topTrailing) {
                AsyncThumbnailImage(itemID: item.coverImageID ?? item.imageIDs.first ?? item.id.uuidString)
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                
                // Selection Checkbox
                if navState.isEditMode {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.itabinderGreen : Color.white.opacity(0.8))
                            .frame(width: 26, height: 26)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .stroke(Color.itabinderGreen, lineWidth: 2)
                                .frame(width: 26, height: 26)
                        }
                    }
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(
                isSelected ? Color.itabinderGreen.opacity(0.1) : Color.clear
            )
            
            // Text Area
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(alignment: .center) {
                    Text(item.ipName.isEmpty ? "Unknown" : item.ipName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Quantity and Price/Status
                    HStack(spacing: 4) {
                        if !navState.isEditMode && item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                        
                        if item.holdingStatus != "已持有" {
                            Text(item.holdingStatus)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        } else if let price = item.price {
                            Text(currencySymbol + String(format: "%.0f", price))
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.itabinderGreen.opacity(0.12))
                                .foregroundColor(.itabinderGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground).opacity(isSelected ? 0.8 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.primary.opacity(0.06), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.itabinderGreen : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onLongPressGesture(minimumDuration: 0.5) {
            if !navState.isEditMode {
                HapticManager.shared.impact(.medium)
                withAnimation {
                    navState.isEditMode = true
                    navState.selectedItemIDs.insert(item.id)
                }
            }
        }
    }

    
    private var currencySymbol: String {
        switch item.currency.uppercased() {
        case "CNY": return "¥"
        case "JPY": return "円"
        case "USD": return "$"
        case "EUR": return "€"
        default: return ""
        }
    }
}

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if title.contains("金额") || title.contains("消费") {
                        Text("¥")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Text(value)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        StatsCard(title: "总金额", value: "7,804.02", subtitle: nil, color: .itabinderGreen)
        StatsCard(title: "2025年消费", value: "7,537.02", subtitle: nil, color: .orange)
    }
    .padding()
}

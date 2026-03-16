import SwiftUI
import SwiftData

struct DevotionView: View {
    @Query private var allItems: [Item]
    
    private var totalSpend: Double {
        StatsService.shared.calculateTotalSpend(items: allItems)
    }
    
    private var monthlySpend: Double {
        StatsService.shared.calculateMonthlySpend(items: allItems)
    }
    
    private var totalQuantity: Int {
        StatsService.shared.calculateTotalQuantity(items: allItems)
    }
    
    private var yearlyHistory: [StatsService.YearlySpend] {
        StatsService.shared.calculateYearlyHistory(items: allItems)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("统计")
                                .font(.title2.bold())
                            Text("数据概览")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(Color.itabinderGreen.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.itabinderGreen)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main Stats Cards
                    VStack(spacing: 12) {
                        StatsCard(
                            title: "总金额",
                            value: formatCurrency(totalSpend),
                            subtitle: nil,
                            color: .itabinderGreen
                        )
                        
                        HStack(spacing: 12) {
                            StatsCard(
                                title: "本月购买额",
                                value: formatCurrency(monthlySpend),
                                subtitle: nil,
                                color: .itabinderGreen
                            )
                        }
                        
                        StatsCard(
                            title: "合集内周边",
                            value: "\(totalQuantity)",
                            subtitle: nil,
                            color: .itabinderGreen
                        )
                    }
                    .padding(.horizontal)
                    
                    // History Section Header
                    Text("消费历史")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Yearly Cards
                    VStack(spacing: 12) {
                        ForEach(yearlyHistory) { history in
                            StatsCard(
                                title: "\(history.year)年消费",
                                value: formatCurrency(history.amount),
                                subtitle: nil,
                                color: .itabinderGreen
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bottom Spacer for TabBar
                    Color.clear.frame(height: 100)
                }
            }
            .background(DynamicGlassBackground())
            .navigationBarHidden(true)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }
}

#Preview {
    DevotionView()
        .modelContainer(for: Item.self, inMemory: true)
}

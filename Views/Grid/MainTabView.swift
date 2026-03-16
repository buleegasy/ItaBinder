import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isShowingImport = false
    @State private var navState = MainNavigationState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            DynamicGlassBackground()
            
            // Main Content Area
            Group {
                if selectedTab == 0 {
                    HomeView()
                } else if selectedTab == 1 {
                    CollectionsView()
                } else {
                    DevotionView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(navState)
            .safeAreaInset(edge: .bottom) {
                if navState.isTabBarVisible {
                    Color.clear.frame(height: 90)
                }
            }
            
            // Custom Tab Bar
            if navState.isTabBarVisible {
                customTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: navState.isTabBarVisible)
    }
    
    var customTabBar: some View {
        HStack(spacing: 12) {
            // Tabs Capsule
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
                
                HStack(spacing: 0) {
                    tabButton(title: "我的展柜", icon: "house.fill", index: 0)
                    tabButton(title: "谷子分类", icon: "square.grid.2x2.fill", index: 1)
                    tabButton(title: "统计", icon: "chart.bar.fill", index: 2)
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 64)
            .shadow(color: Color.primary.opacity(0.1), radius: 15, x: 0, y: 10)
            
            // Standalone Plus Button
            Button(action: {
                HapticManager.shared.impact(.medium)
                isShowingImport = true
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                        )
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.itabinderGreen, .itabinderLightGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 64, height: 64)
            }
            .shadow(color: .itabinderGreen.opacity(0.4), radius: 12, x: 0, y: 6)
            .sheet(isPresented: $isShowingImport) {
                NavigationStack {
                    ImageImportView()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            if selectedTab != index {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = index
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == index ? .bold : .medium))
            }
            .foregroundColor(selectedTab == index ? .itabinderGreen : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    MainTabView()
}

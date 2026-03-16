import SwiftUI

struct DynamicGlassBackground: View {
    @State private var startAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Base background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Animated glowing orbs
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                ZStack {
                    // Top left animated glow - Fibonacci 34
                    Circle()
                        .fill(Color.itabinderLightGreen.opacity(0.18))
                        .frame(width: width * 0.7, height: width * 0.7)
                        .blur(radius: 34)
                        .offset(x: startAnimation ? -width * 0.15 : 0,
                                y: startAnimation ? -height * 0.1 : height * 0.05)
                    
                    // Center right animated glow - Fibonacci 55
                    Circle()
                        .fill(Color.itabinderGreen.opacity(0.12))
                        .frame(width: width * 0.85, height: width * 0.85)
                        .blur(radius: 55)
                        .offset(x: startAnimation ? width * 0.25 : width * 0.05,
                                y: startAnimation ? height * 0.15 : -height * 0.05)
                    
                    // Bottom left deep glow - Fibonacci 89
                    Circle()
                        .fill(Color.itabinderDeepGreen.opacity(0.15))
                        .frame(width: width, height: width)
                        .blur(radius: 89)
                        .offset(x: startAnimation ? -width * 0.05 : width * 0.15,
                                y: startAnimation ? height * 0.35 : height * 0.6)

                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        startAnimation = true
                    }
                }
            }
            .ignoresSafeArea()
            
            // Frosted glass overlay to blend it all together smoothly
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    DynamicGlassBackground()
}

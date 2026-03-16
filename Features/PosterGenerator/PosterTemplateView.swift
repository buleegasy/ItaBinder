import SwiftUI

// MARK: - Poster Template Router

struct PosterTemplateView: View {
    let items: [PosterItemSnapshot]
    let config: PosterConfiguration
    let colors: DominantColors
    
    private let size = kPosterRenderSize
    private var unit: CGFloat { size.width / 40.0 }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background from image colors
            organicGradientBackground
            
            // Decoration layer
            if config.decoration != .none {
                decorationLayer
            }
            
            // Content
            switch config.template {
            case .showcase:
                ShowcasePoster(items: items, config: config, colors: colors)
            case .catalog:
                CatalogPoster(items: items, config: config, colors: colors)
            case .highlight:
                HighlightPoster(items: items, config: config, colors: colors)
            }
            
            // Watermark
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("ItaBinder")
                        .font(.system(size: unit * 0.7, weight: .medium, design: .monospaced))
                        .foregroundColor(colors.textColor.opacity(0.2))
                        .padding(unit * 1.5)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
    
    // MARK: - Apple Music-style Organic Gradient
    
    private var organicGradientBackground: some View {
        ZStack {
            // Base white/off-white
            Color.white
            
            // Top-left warm blob
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [colors.primary.opacity(0.7), colors.primary.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.6
                    )
                )
                .frame(width: size.width * 1.2, height: size.height * 0.5)
                .offset(x: -size.width * 0.2, y: -size.height * 0.25)
            
            // Top-right cool blob
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [colors.secondary.opacity(0.55), colors.secondary.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.5
                    )
                )
                .frame(width: size.width * 0.9, height: size.height * 0.4)
                .offset(x: size.width * 0.3, y: -size.height * 0.3)
            
            // Center warm accent
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [colors.tertiary.opacity(0.35), colors.tertiary.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.4
                    )
                )
                .frame(width: size.width * 0.7, height: size.height * 0.35)
                .offset(x: -size.width * 0.05, y: -size.height * 0.08)
            
            // Subtle bottom wash
            LinearGradient(
                colors: [.clear, colors.primary.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    private var decorationLayer: some View {
        switch config.decoration {
        case .sparkle:
            SparkleDecorationView(size: size, accentColor: colors.primary)
        case .dots:
            DotsDecorationView(size: size, accentColor: colors.secondary)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - 1. Showcase Poster (Classic Apple Music-style)

struct ShowcasePoster: View {
    let items: [PosterItemSnapshot]
    let config: PosterConfiguration
    let colors: DominantColors
    
    private let size = kPosterRenderSize
    private var unit: CGFloat { size.width / 40.0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: unit * 0.3) {
                Text("养谷")
                    .font(.system(size: unit * 1.2, weight: .bold))
                    .foregroundColor(colors.textColor.opacity(0.5))
                
                Spacer().frame(height: unit * 2)
                
                Text(config.customTitle)
                    .font(.system(size: unit * 3.2, weight: .bold, design: .rounded))
                    .foregroundColor(colors.textColor)
                    .lineLimit(2)
                
                Text("\(items.count) 件收藏")
                    .font(.system(size: unit * 1.0, weight: .regular))
                    .foregroundColor(colors.secondaryText)
            }
            .padding(.horizontal, unit * 2.5)
            .padding(.top, unit * 4)
            
            Spacer().frame(height: unit * 3)
            
            // Item List
            VStack(alignment: .leading, spacing: unit * 1.8) {
                ForEach(Array(items.prefix(8).enumerated()), id: \.element.id) { index, item in
                    itemRow(item, index: index + 1)
                }
            }
            .padding(.horizontal, unit * 2.5)
            
            Spacer()
            
            // Bottom image strip (bleeds out like Apple Music)
            imageStrip
        }
    }
    
    private func itemRow(_ item: PosterItemSnapshot, index: Int) -> some View {
        HStack(alignment: .top, spacing: unit * 1.2) {
            Text("\(index)")
                .font(.system(size: unit * 1.1, weight: .bold))
                .foregroundColor(colors.textColor.opacity(0.25))
                .frame(width: unit * 1.8, alignment: .leading)
            
            VStack(alignment: .leading, spacing: unit * 0.15) {
                if config.showTitle {
                    Text(item.title)
                        .font(.system(size: unit * 1.05, weight: .semibold))
                        .foregroundColor(colors.textColor)
                        .lineLimit(1)
                }
                
                HStack(spacing: unit * 0.5) {
                    if config.showIPName && !item.ipName.isEmpty {
                        Text(item.ipName)
                            .font(.system(size: unit * 0.75))
                            .foregroundColor(colors.secondaryText)
                            .lineLimit(1)
                    }
                    if config.showBrand && !item.brand.isEmpty {
                        Text("· \(item.brand)")
                            .font(.system(size: unit * 0.75))
                            .foregroundColor(colors.secondaryText.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if config.showPrice, let price = item.formattedPrice {
                Text(price)
                    .font(.system(size: unit * 0.85, weight: .semibold, design: .rounded))
                    .foregroundColor(colors.textColor.opacity(0.6))
            }
        }
    }
    
    private var imageStrip: some View {
        // Bottom row of images that bleeds off the edge
        HStack(spacing: unit * 0.3) {
            ForEach(items.prefix(6)) { item in
                if let img = item.image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: size.width / CGFloat(min(items.count, 6)),
                            height: size.width / CGFloat(min(items.count, 6)) * 1.2
                        )
                        .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

// MARK: - 2. Catalog Poster (Two-column numbered list)

struct CatalogPoster: View {
    let items: [PosterItemSnapshot]
    let config: PosterConfiguration
    let colors: DominantColors
    
    private let size = kPosterRenderSize
    private var unit: CGFloat { size.width / 40.0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: unit * 0.3) {
                Text("养谷")
                    .font(.system(size: unit * 1.2, weight: .bold))
                    .foregroundColor(colors.textColor.opacity(0.5))
                
                Spacer().frame(height: unit * 1.5)
                
                Text(config.customTitle)
                    .font(.system(size: unit * 2.6, weight: .bold))
                    .foregroundColor(colors.textColor)
                    .lineLimit(2)
                
                Text(Date.now.formatted(.dateTime.year()))
                    .font(.system(size: unit * 1.5, weight: .bold))
                    .foregroundColor(colors.primary.opacity(0.6))
            }
            .padding(.horizontal, unit * 2.5)
            .padding(.top, unit * 4)
            
            Spacer().frame(height: unit * 3)
            
            // Two-column layout
            let leftItems = Array(items.prefix(5))
            let rightItems = Array(items.dropFirst(5).prefix(5))
            
            HStack(alignment: .top, spacing: unit * 0.5) {
                // Left column
                VStack(alignment: .leading, spacing: unit * 2.5) {
                    ForEach(Array(leftItems.enumerated()), id: \.element.id) { index, item in
                        catalogEntry(item, index: index + 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right column
                if !rightItems.isEmpty {
                    VStack(alignment: .leading, spacing: unit * 2.5) {
                        ForEach(Array(rightItems.enumerated()), id: \.element.id) { index, item in
                            catalogEntry(item, index: index + leftItems.count + 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, unit * 2.5)
            
            Spacer()
            
            // Bottom circular image strip
            circularImageStrip
        }
    }
    
    private func catalogEntry(_ item: PosterItemSnapshot, index: Int) -> some View {
        HStack(alignment: .top, spacing: unit * 0.8) {
            Text("\(index)")
                .font(.system(size: unit * 1.0, weight: .bold))
                .foregroundColor(colors.textColor.opacity(0.2))
                .frame(width: unit * 1.6, alignment: .leading)
            
            VStack(alignment: .leading, spacing: unit * 0.1) {
                if config.showTitle {
                    Text(item.title)
                        .font(.system(size: unit * 0.9, weight: .semibold))
                        .foregroundColor(colors.textColor)
                        .lineLimit(2)
                }
                if config.showIPName && !item.ipName.isEmpty {
                    Text(item.ipName)
                        .font(.system(size: unit * 0.7, weight: .regular))
                        .foregroundColor(colors.secondaryText)
                        .lineLimit(1)
                }
                if config.showPrice, let price = item.formattedPrice {
                    Text(price)
                        .font(.system(size: unit * 0.7, weight: .semibold, design: .rounded))
                        .foregroundColor(colors.textColor.opacity(0.5))
                }
            }
        }
    }
    
    private var circularImageStrip: some View {
        HStack(spacing: unit * 0.6) {
            ForEach(items.prefix(8)) { item in
                if let img = item.image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: unit * 4.5, height: unit * 4.5)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, unit)
        .padding(.bottom, unit * 2)
    }
}

// MARK: - 3. Highlight Poster (Hero image + details)

struct HighlightPoster: View {
    let items: [PosterItemSnapshot]
    let config: PosterConfiguration
    let colors: DominantColors
    
    private let size = kPosterRenderSize
    private var unit: CGFloat { size.width / 40.0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: unit * 0.2) {
                    Text("养谷")
                        .font(.system(size: unit * 1.2, weight: .bold))
                        .foregroundColor(colors.textColor.opacity(0.5))
                }
                Spacer()
                Text("\(items.count) 件")
                    .font(.system(size: unit * 0.8, weight: .medium, design: .monospaced))
                    .foregroundColor(colors.secondaryText)
            }
            .padding(.horizontal, unit * 2.5)
            .padding(.top, unit * 3.5)
            
            Spacer().frame(height: unit * 1.5)
            
            // Custom title, big and bold
            Text(config.customTitle)
                .font(.system(size: unit * 3.0, weight: .black))
                .foregroundColor(colors.textColor)
                .lineLimit(2)
                .padding(.horizontal, unit * 2.5)
            
            Spacer().frame(height: unit * 2)
            
            // Hero image (first item, large)
            if let firstItem = items.first, let img = firstItem.image {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width - unit * 5, height: size.width * 0.7)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: unit * 1.2))
                    
                    // Gradient overlay for text readability
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: unit * 6)
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: unit * 1.2,
                            bottomTrailingRadius: unit * 1.2
                        )
                    )
                    
                    // Hero item info
                    VStack(alignment: .leading, spacing: unit * 0.15) {
                        if config.showTitle {
                            Text(firstItem.title)
                                .font(.system(size: unit * 1.1, weight: .bold))
                                .foregroundColor(.white)
                        }
                        if config.showIPName && !firstItem.ipName.isEmpty {
                            Text(firstItem.ipName)
                                .font(.system(size: unit * 0.75))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(unit * 1.2)
                }
                .padding(.horizontal, unit * 2.5)
            }
            
            Spacer().frame(height: unit * 2)
            
            // Remaining items as compact list
            VStack(alignment: .leading, spacing: unit * 1.2) {
                ForEach(Array(items.dropFirst().prefix(6).enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: unit * 1.0) {
                        if let img = item.image {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: unit * 3.5, height: unit * 3.5)
                                .clipShape(RoundedRectangle(cornerRadius: unit * 0.5))
                        }
                        
                        VStack(alignment: .leading, spacing: unit * 0.08) {
                            if config.showTitle {
                                Text(item.title)
                                    .font(.system(size: unit * 0.8, weight: .medium))
                                    .foregroundColor(colors.textColor)
                                    .lineLimit(1)
                            }
                            if config.showIPName && !item.ipName.isEmpty {
                                Text(item.ipName)
                                    .font(.system(size: unit * 0.6))
                                    .foregroundColor(colors.secondaryText)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if config.showPrice, let price = item.formattedPrice {
                            Text(price)
                                .font(.system(size: unit * 0.7, weight: .semibold, design: .rounded))
                                .foregroundColor(colors.textColor.opacity(0.5))
                        }
                    }
                }
            }
            .padding(.horizontal, unit * 2.5)
            
            Spacer()
        }
    }
}

// MARK: - Decoration Views

struct SparkleDecorationView: View {
    let size: CGSize
    let accentColor: Color
    
    var body: some View {
        Canvas { context, canvasSize in
            let sparkles = generatePositions(count: 25, in: canvasSize)
            for sparkle in sparkles {
                let symbol = context.resolve(
                    Text("✦")
                        .font(.system(size: sparkle.size))
                        .foregroundColor(accentColor.opacity(sparkle.opacity))
                )
                context.draw(symbol, at: sparkle.point)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
    
    private func generatePositions(count: Int, in size: CGSize) -> [(point: CGPoint, size: CGFloat, opacity: Double)] {
        var result: [(CGPoint, CGFloat, Double)] = []
        for i in 0..<count {
            let seed = Double(i) * 137.508
            let x = CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * size.width
            let y = CGFloat((seed * 0.382).truncatingRemainder(dividingBy: 1.0)) * size.height
            let s = CGFloat(6 + Int(seed * 3) % 10)
            let o = 0.04 + (seed * 0.1).truncatingRemainder(dividingBy: 0.08)
            result.append((CGPoint(x: x, y: y), s, o))
        }
        return result
    }
}

struct DotsDecorationView: View {
    let size: CGSize
    let accentColor: Color
    
    var body: some View {
        Canvas { context, canvasSize in
            let spacing: CGFloat = size.width / 18
            let dotSize: CGFloat = size.width * 0.003
            
            var y: CGFloat = spacing / 2
            while y < canvasSize.height {
                var x: CGFloat = spacing / 2
                while x < canvasSize.width {
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(accentColor.opacity(0.05)))
                    x += spacing
                }
                y += spacing
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

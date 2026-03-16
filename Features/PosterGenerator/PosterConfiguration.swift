import Foundation
import SwiftUI
import UIKit

// MARK: - Poster Template Style

enum PosterTemplate: String, CaseIterable, Identifiable {
    case showcase = "展柜"
    case catalog = "图鉴"
    case highlight = "精选"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .showcase: return "rectangle.grid.2x2"
        case .catalog: return "list.number"
        case .highlight: return "star.square.on.square"
        }
    }
    
    var subtitle: String {
        switch self {
        case .showcase: return "精美展示你的收藏"
        case .catalog: return "清晰列出每一件"
        case .highlight: return "突出你的最爱"
        }
    }
}

// MARK: - Decoration

enum PosterDecoration: String, CaseIterable, Identifiable {
    case none = "无"
    case sparkle = "✦ 闪光"
    case dots = "● 波点"
    
    var id: String { rawValue }
}

// MARK: - Configuration

struct PosterConfiguration {
    var template: PosterTemplate = .showcase
    var decoration: PosterDecoration = .none
    var customTitle: String = "我的收藏"
    
    // Content visibility toggles
    var showTitle: Bool = true
    var showIPName: Bool = true
    var showPrice: Bool = false
    var showBrand: Bool = false
    var showStatus: Bool = false
}

// MARK: - Fixed Poster Size (9:16 portrait, phone-screen)

let kPosterRenderSize = CGSize(width: 1080, height: 1920)

// MARK: - Item Snapshot

struct PosterItemSnapshot: Identifiable {
    let id: UUID
    let title: String
    let ipName: String
    let price: Double?
    let currency: String
    let brand: String
    let holdingStatus: String
    let image: UIImage?
    
    var formattedPrice: String? {
        guard let price = price else { return nil }
        let symbol: String
        switch currency.uppercased() {
        case "CNY": symbol = "¥"
        case "JPY": symbol = "円"
        case "USD": symbol = "$"
        default: symbol = ""
        }
        return symbol + String(format: "%.0f", price)
    }
    
    init(from item: Item) {
        self.id = item.id
        self.title = item.title
        self.ipName = item.ipName
        self.price = item.price
        self.currency = item.currency
        self.brand = item.brand
        self.holdingStatus = item.holdingStatus
        
        let imageID = item.coverImageID ?? item.imageIDs.first ?? item.id.uuidString
        self.image = ImageStorageManager.shared.load(for: imageID, type: .display)
            ?? ImageStorageManager.shared.load(for: imageID, type: .original)
    }
}

// MARK: - Dominant Color Extraction

struct DominantColors {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let isDark: Bool
    
    var textColor: Color {
        isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    var secondaryText: Color {
        isDark ? .white.opacity(0.7) : Color(red: 0.3, green: 0.3, blue: 0.3)
    }
    
    static let fallback = DominantColors(
        primary: Color(red: 1.0, green: 0.6, blue: 0.3),
        secondary: Color(red: 0.3, green: 0.8, blue: 0.7),
        tertiary: Color(red: 1.0, green: 0.85, blue: 0.3),
        isDark: false
    )
}

extension UIImage {
    /// Extracts 3 dominant colors from a UIImage using k-means-like sampling.
    func extractDominantColors() -> DominantColors {
        guard let cgImage = self.cgImage else { return .fallback }
        
        // Downscale for performance
        let sampleSize = 40
        guard let context = CGContext(
            data: nil,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .fallback }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))
        
        guard let data = context.data else { return .fallback }
        let pointer = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)
        
        var rTotal: [Double] = [0, 0, 0]
        var gTotal: [Double] = [0, 0, 0]
        var bTotal: [Double] = [0, 0, 0]
        var counts: [Double] = [0, 0, 0]
        
        for y in 0..<sampleSize {
            for x in 0..<sampleSize {
                let offset = (y * sampleSize + x) * 4
                let r = Double(pointer[offset]) / 255.0
                let g = Double(pointer[offset + 1]) / 255.0
                let b = Double(pointer[offset + 2]) / 255.0
                
                // Skip very dark or very bright pixels
                let brightness = (r + g + b) / 3.0
                if brightness < 0.05 || brightness > 0.95 { continue }
                
                // Assign to one of 3 buckets based on hue
                let maxC = max(r, g, b)
                let minC = min(r, g, b)
                let delta = maxC - minC
                
                var hue: Double = 0
                if delta > 0.01 {
                    if maxC == r { hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
                    else if maxC == g { hue = (b - r) / delta + 2 }
                    else { hue = (r - g) / delta + 4 }
                    hue /= 6.0
                    if hue < 0 { hue += 1 }
                }
                
                let bucket: Int
                if hue < 0.33 { bucket = 0 }
                else if hue < 0.66 { bucket = 1 }
                else { bucket = 2 }
                
                rTotal[bucket] += r
                gTotal[bucket] += g
                bTotal[bucket] += b
                counts[bucket] += 1
            }
        }
        
        // Compute averages, with saturation boost
        func makeColor(_ idx: Int) -> Color {
            guard counts[idx] > 0 else {
                // Fallback colors
                let fallbacks: [(Double, Double, Double)] = [
                    (1.0, 0.6, 0.3), (0.3, 0.8, 0.7), (1.0, 0.85, 0.3)
                ]
                return Color(red: fallbacks[idx].0, green: fallbacks[idx].1, blue: fallbacks[idx].2)
            }
            var r = rTotal[idx] / counts[idx]
            var g = gTotal[idx] / counts[idx]
            var b = bTotal[idx] / counts[idx]
            
            // Boost saturation slightly for more vibrant gradients
            let avg = (r + g + b) / 3.0
            let boost = 1.3
            r = avg + (r - avg) * boost
            g = avg + (g - avg) * boost
            b = avg + (b - avg) * boost
            
            // Brighten for gradient visibility
            let brighten = 0.15
            r = min(1, r + brighten)
            g = min(1, g + brighten)
            b = min(1, b + brighten)
            
            return Color(red: r.clamped(to: 0...1), green: g.clamped(to: 0...1), blue: b.clamped(to: 0...1))
        }
        
        // Determine overall brightness for text color
        let totalPixels = counts.reduce(0, +)
        let overallBrightness = totalPixels > 0
            ? (rTotal.reduce(0, +) + gTotal.reduce(0, +) + bTotal.reduce(0, +)) / (totalPixels * 3.0)
            : 0.5
        
        return DominantColors(
            primary: makeColor(0),
            secondary: makeColor(1),
            tertiary: makeColor(2),
            isDark: overallBrightness < 0.4
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

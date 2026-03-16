import SwiftUI
import UIKit

@MainActor
final class PosterRenderService {
    static let shared = PosterRenderService()
    private init() {}
    
    /// Renders a poster to a high-quality UIImage.
    func render(items: [PosterItemSnapshot], config: PosterConfiguration, colors: DominantColors) -> UIImage? {
        let posterView = PosterTemplateView(items: items, config: config, colors: colors)
        
        let renderer = ImageRenderer(content: posterView)
        renderer.scale = 3.0
        
        return renderer.uiImage
    }
    
    /// Extracts dominant colors from the items' images.
    func extractColors(from items: [PosterItemSnapshot]) -> DominantColors {
        // Merge dominant colors from all items' images
        guard let firstImage = items.compactMap({ $0.image }).first else {
            return .fallback
        }
        return firstImage.extractDominantColors()
    }
    
    /// Exports to PNG for sharing.
    func exportToPNG(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ItaBinder_Poster_\(UUID().uuidString).png")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export poster PNG: \(error)")
            return nil
        }
    }
}

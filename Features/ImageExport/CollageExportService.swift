import SwiftUI
import UIKit

@MainActor
final class CollageExportService {
    static let shared = CollageExportService()
    
    private init() {}
    
    /// Renders a CollageView to a high-quality UIImage using ImageRenderer.
    func renderCollage(images: [UIImage], layout: CollageLayout) -> UIImage? {
        let collageView = CollageView(images: images, layout: layout)
            .environment(\.displayScale, 3.0) // High quality render
        
        let renderer = ImageRenderer(content: collageView)
        renderer.scale = 3.0 // Matches retina display quality or higher
        
        return renderer.uiImage
    }
    
    /// Saves the image as a PNG to a temporary URL for sharing.
    func exportToPNG(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ItaBinder_Collage_\(UUID().uuidString).png")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export PNG: \(error)")
            return nil
        }
    }
}

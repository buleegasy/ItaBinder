import Foundation
import ImageIO
import UIKit

final class ImageImporter {
    static let shared = ImageImporter()
    
    private init() {}
    
    func downsample(at url: URL, toPointSize pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    func processImport(at sourceURL: URL, for itemID: String = UUID().uuidString) async throws -> String {
        // 1. Save original
        let originalData = try Data(contentsOf: sourceURL)
        let _ = try ImageStorageManager.shared.save(data: originalData, for: itemID, type: .original)
        
        // Use the saved original for downsampling to minimize memory footprint
        guard let originalURL = ImageStorageManager.shared.getURL(for: itemID, type: .original) else {
            throw NSError(domain: "ImageImporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Original not found"])
        }
        
        // 2. Generate Display Image (~1024px)
        if let displayImage = downsample(at: originalURL, toPointSize: CGSize(width: 512, height: 512)),
           let displayData = displayImage.jpegData(compressionQuality: 0.8) {
            _ = try ImageStorageManager.shared.save(data: displayData, for: itemID, type: .display)
        }
        
        // 3. Generate Thumbnail (~120px)
        if let thumbnailImage = downsample(at: originalURL, toPointSize: CGSize(width: 120, height: 120)),
           let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) {
            _ = try ImageStorageManager.shared.save(data: thumbnailData, for: itemID, type: .thumb)
        }
        
        return itemID
    }
    
    func batchImport(urls: [URL]) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self) { group in
            for url in urls {
                group.addTask {
                    try await self.processImport(at: url)
                }
            }
            
            var results: [String] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

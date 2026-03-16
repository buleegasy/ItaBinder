import Foundation
import UIKit

final class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    
    enum ImageType: String {
        case thumb = "thumb.jpg"
        case display = "display.jpg"
        case original = "original.jpg"
    }
    
    private var baseDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ItaBinderImages", isDirectory: true)
    }
    
    private init() {
        createBaseDirectoryIfNeeded()
    }
    
    private func createBaseDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Internal API
    
    func createFolder(for itemID: String) throws -> URL {
        let folderURL = baseDirectory.appendingPathComponent(itemID, isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
    
    func save(data: Data, for itemID: String, type: ImageType) throws -> URL {
        let folderURL = try createFolder(for: itemID)
        let fileURL = folderURL.appendingPathComponent(type.rawValue)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    func load(for itemID: String, type: ImageType) -> UIImage? {
        let fileURL = baseDirectory.appendingPathComponent(itemID).appendingPathComponent(type.rawValue)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    func getURL(for itemID: String, type: ImageType) -> URL? {
        let fileURL = baseDirectory.appendingPathComponent(itemID).appendingPathComponent(type.rawValue)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func deleteFolder(for itemID: String) {
        let folderURL = baseDirectory.appendingPathComponent(itemID)
        try? fileManager.removeItem(at: folderURL)
    }
    
    // MARK: - Cleanup Strategy
    
    /// Deletes all folders in the base directory that aren't in the provided list of valid IDs.
    /// This is a maintenance function to cleanup orphaned files.
    func cleanupOrphanedFolders(validIDs: Set<String>) {
        do {
            let itemFolders = try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
            for folderURL in itemFolders {
                let folderName = folderURL.lastPathComponent
                if !validIDs.contains(folderName) {
                    try? fileManager.removeItem(at: folderURL)
                }
            }
        } catch {
            print("Cleanup failed: \(error)")
        }
    }
}

import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Semantic Lifting Engine (Phase 2)

/// Actor-based, thread-safe Vision pipeline for high-precision foreground segmentation.
/// Returns separated CIImage masks for downstream boolean compositing.
actor SemanticLiftingEngine {
    static let shared = SemanticLiftingEngine()
    
    enum LiftingError: Error, LocalizedError {
        case noSubject
        case processingFailed
        case invalidImage
        
        var errorDescription: String? {
            switch self {
            case .noSubject: return "无法识别主体"
            case .processingFailed: return "处理失败"
            case .invalidImage: return "无效图片"
            }
        }
    }
    
    /// Generate a high-resolution foreground mask aligned to the original image coordinates.
    /// Returns a single-channel CIImage mask at the original image resolution.
    func generateHighResAIMask(from image: UIImage) throws -> CIImage {
        guard let cgImage = image.cgImage else { throw LiftingError.invalidImage }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        try handler.perform([request])
        
        guard let result = request.results?.first else {
            throw LiftingError.noSubject
        }
        
        let maskPixelBuffer = try result.generateScaledMaskForImage(
            forInstances: result.allInstances,
            from: handler
        )
        
        return CIImage(cvPixelBuffer: maskPixelBuffer)
    }
    
    /// Convenience: one-shot background removal (for simple use cases).
    /// Uses CompositingPipeline internally for the final blend.
    func removeBackground(from image: UIImage) throws -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let aiMask = try generateHighResAIMask(from: image)
        
        // Ensure originalCI matches the orientation used for the mask
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let originalCI = CIImage(cgImage: cgImage).oriented(orientation)
        
        return CompositingPipeline.applySimpleMask(
            originalImage: originalCI,
            mask: aiMask,
            featherRadius: 0.5,
            scale: image.scale,
            orientation: .up // CIImage already oriented, return as .up
        )
    }
}

// MARK: - Orientation Helpers

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Legacy compatibility wrapper
final class BackgroundRemovalService {
    static let shared = BackgroundRemovalService()
    private init() {}
    
    func removeBackground(from image: UIImage) async throws -> UIImage? {
        return try await SemanticLiftingEngine.shared.removeBackground(from: image)
    }
}

// MARK: - Metal Compositing Pipeline (Phase 4)

/// GPU-accelerated mask compositing using Core Image filter chains.
/// All operations are compiled to Metal shaders by the system.
final class CompositingPipeline {
    
    /// Shared high-performance CIContext (GPU mode, reused to avoid creation overhead).
    static let sharedContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .highQualityDownsample: true
    ])
    
    /// Simple mask application with optional feathering.
    static func applySimpleMask(
        originalImage: CIImage,
        mask: CIImage,
        featherRadius: Float = 0.5,
        scale: CGFloat = 1.0,
        orientation: UIImage.Orientation = .up
    ) -> UIImage? {
        // 1. Scale mask to match inputImage extent
        var finalMask = mask
        let inputExtent = originalImage.extent
        let maskExtent = mask.extent
        
        if inputExtent.size != maskExtent.size {
            let scaleX = inputExtent.width / maskExtent.width
            let scaleY = inputExtent.height / maskExtent.height
            
            // Robust scaling: Move to (0,0), scale, move to target origin
            finalMask = mask.transformed(by: CGAffineTransform(translationX: -maskExtent.origin.x, y: -maskExtent.origin.y))
                            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                            .transformed(by: CGAffineTransform(translationX: inputExtent.origin.x, y: inputExtent.origin.y))
                            .cropped(to: inputExtent)
        }
        
        // 2. Optional anti-aliasing feather
        if featherRadius > 0 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = finalMask
            blur.radius = featherRadius
            if let blurred = blur.outputImage {
                finalMask = blurred.cropped(to: inputExtent)
            }
        }
        
        // 2. Blend with transparent background
        let blend = CIFilter.blendWithMask()
        blend.inputImage = originalImage
        blend.maskImage = finalMask
        blend.backgroundImage = CIImage.clear.cropped(to: inputExtent)
        
        guard let output = blend.outputImage,
              let cgImage = sharedContext.createCGImage(output, from: inputExtent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
    }
    
    /// Boolean refinement: Final = AI_Mask × Invert(Flood_Mask)
    /// Removes user-marked blemish regions from the AI mask before compositing.
    static func applyRefinement(
        originalImage: CIImage,
        aiMask: CIImage,
        floodMask: CIImage,
        featherRadius: Float = 0.5
    ) -> UIImage? {
        let targetExtent = originalImage.extent
        
        // 1. Scale both masks to target resolution
        var scaledAI = aiMask
        if aiMask.extent.size != targetExtent.size {
            let sX = targetExtent.width / aiMask.extent.width
            let sY = targetExtent.height / aiMask.extent.height
            scaledAI = aiMask.transformed(by: CGAffineTransform(translationX: -aiMask.extent.origin.x, y: -aiMask.extent.origin.y))
                             .transformed(by: CGAffineTransform(scaleX: sX, y: sY))
                             .transformed(by: CGAffineTransform(translationX: targetExtent.origin.x, y: targetExtent.origin.y))
                             .cropped(to: targetExtent)
        }
        
        var scaledFlood = floodMask
        if floodMask.extent.size != targetExtent.size {
            let sX = targetExtent.width / floodMask.extent.width
            let sY = targetExtent.height / floodMask.extent.height
            scaledFlood = floodMask.transformed(by: CGAffineTransform(translationX: -floodMask.extent.origin.x, y: -floodMask.extent.origin.y))
                                   .transformed(by: CGAffineTransform(scaleX: sX, y: sY))
                                   .transformed(by: CGAffineTransform(translationX: targetExtent.origin.x, y: targetExtent.origin.y))
                                   .cropped(to: targetExtent)
        }
        
        // 2. Invert flood mask (blemish areas become black)
        let invert = CIFilter.colorInvert()
        invert.inputImage = scaledFlood
        guard let invertedFlood = invert.outputImage else { return nil }
        
        // 3. Boolean multiply: only pixels that are BOTH foreground AND not blemish survive
        let multiply = CIFilter.multiplyCompositing()
        multiply.inputImage = scaledAI
        multiply.backgroundImage = invertedFlood
        guard let booleanMask = multiply.outputImage else { return nil }
        
        // 4. Apply the refined mask
        return applySimpleMask(
            originalImage: originalImage,
            mask: booleanMask,
            featherRadius: featherRadius
        )
    }
}

extension UIImage {
    /// Returns a new image with .up orientation, which is required for raw pixel processing.
    func normalized() -> UIImage? {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

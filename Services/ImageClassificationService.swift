import Foundation
import Vision
import UIKit
import CoreImage

/// A service to visually classify images and suggest relevant tags.
final class ImageClassificationService {
    static let shared = ImageClassificationService()
    
    private init() {}
    
    /// Classifies an image and returns the top 5 relevant labels.
    func suggestTags(for image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            // Filter: Significant confidence (e.g. > 5%) and take top 5
            let topLabels = observations
                .filter { $0.confidence > 0.05 }
                .prefix(5)
                .map { observation in
                    // Format the label: "plastic_bottle" -> "Plastic Bottle"
                    observation.identifier
                        .replacingOccurrences(of: "_", with: " ")
                        .capitalized
                }
            
            return topLabels
            
        } catch {
            print("Image classification failed: \(error)")
            return []
        }
    }
    
    /// Generates a subject mask using Vision's subject segmentation
    func generateMask(for image: CIImage) -> CIImage? {
        guard let cgImage = CIContext().createCGImage(image, from: image.extent) else {
            return nil
        }
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let result = request.results?.first else {
                return nil
            }
            
            let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: mask)
            
        } catch {
            print("Mask generation failed: \(error)")
            return nil
        }
    }
}

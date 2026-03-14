import Foundation
import Vision
import UIKit

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
            
            guard let observations = request.results as? [VNClassificationObservation] else {
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
}

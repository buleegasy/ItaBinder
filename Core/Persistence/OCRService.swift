import Foundation
import Vision
import UIKit

/// A service to extract text from images to provide title suggestions.
final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Processes an image and returns a list of sorted text candidates.
    func suggestTitles(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Prefer specific languages if known (e.g. Japanese/English for anime goods)
        request.recognitionLanguages = ["ja-JP", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else { return [] }
            
            let candidates = observations.compactMap { observation -> String? in
                // Get the top candidate for this observation
                guard let candidate = observation.topCandidates(1).first else { return nil }
                
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Filter: Ignore short or mostly numeric/symbolic strings
                if text.count < 4 { return nil }
                if text.rangeOfCharacter(from: .letters) == nil { return nil }
                
                return text
            }
            
            // Rank: Higher confidence first, then longer strings (often titles are longer than price tags)
            // But for now, just return unique, cleaned strings
            return Array(Set(candidates)).sorted { $0.count > $1.count }
            
        } catch {
            print("OCR failed: \(error)")
            return []
        }
    }
}

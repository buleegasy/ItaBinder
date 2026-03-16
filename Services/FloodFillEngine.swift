import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Native flood fill engine using Core Image for interactive mask refinement.
/// Provides pixel-level tolerance-based selection without requiring OpenCV.
final class FloodFillEngine {
    
    private let ciContext = CompositingPipeline.sharedContext
    
    /// Engine type for flood fill operation.
    enum EngineType {
        case nativeSwift
        case openCV
    }
    
    /// Applies a bilateral filter using OpenCV to smooth the image while preserving edges.
    func applyBilateralFilter(to image: UIImage) -> UIImage {
        return OpenCVBridge.applyBilateralFilter(image)
    }
    
    /// Generate a flood fill mask from a seed point with a given color tolerance.
    /// - Parameters:
    ///   - image: The source image.
    ///   - seedPoint: The tap location in image coordinates.
    ///   - tolerance: Color similarity threshold (0-1.0 for native, 0-255 for CV).
    ///   - engine: The algorithmic engine to use.
    /// - Returns: A binary mask UIImage.
    func generateFloodMask(
        from image: UIImage,
        seedPoint: CGPoint,
        tolerance: CGFloat,
        engine: EngineType = .openCV
    ) -> UIImage? {
        if engine == .openCV {
            let scale = image.scale
            let pixelPoint = CGPoint(x: seedPoint.x * scale, y: seedPoint.y * scale)
            // OpenCV expects 0-255 tolerance
            let cvTolerance = tolerance * 255.0
            return OpenCVBridge.generateFloodMask(image, at: pixelPoint, tolerance: cvTolerance)
        }
        
        return generateNativeFloodMask(from: image, seedPoint: seedPoint, tolerance: tolerance)
    }
    
    private func generateNativeFloodMask(
        from image: UIImage,
        seedPoint: CGPoint,
        tolerance: CGFloat
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // 1. Read pixel data
        guard let pixelData = cgImage.dataProvider?.data,
              let dataPtr = CFDataGetBytePtr(pixelData) else { return nil }
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        // 2. Get seed color - APPLY SCALE to point coordinates
        let scale = image.scale
        let seedX = Int(seedPoint.x * scale)
        let seedY = Int(seedPoint.y * scale)
        guard seedX >= 0, seedX < width, seedY >= 0, seedY < height else { return nil }
        
        let seedOffset = seedY * bytesPerRow + seedX * bytesPerPixel
        let seedR = CGFloat(dataPtr[seedOffset]) / 255.0
        let seedG = CGFloat(dataPtr[seedOffset + 1]) / 255.0
        let seedB = CGFloat(dataPtr[seedOffset + 2]) / 255.0
        
        // 3. BFS flood fill - OPTIMIZED QUEUE
        let tolSq = tolerance * tolerance * 3.0
        var visited = [Bool](repeating: false, count: width * height)
        var maskData = [UInt8](repeating: 0, count: width * height)
        
        var queue: [(Int, Int)] = [(seedX, seedY)]
        var head = 0 // use pointer for O(1) dequeue
        visited[seedY * width + seedX] = true
        
        let dx = [0, 0, 1, -1, 1, -1, 1, -1]
        let dy = [1, -1, 0, 0, 1, -1, -1, 1]
        
        while head < queue.count {
            let (cx, cy) = queue[head]
            head += 1
            
            // Check color similarity
            let offset = cy * bytesPerRow + cx * bytesPerPixel
            let r = CGFloat(dataPtr[offset]) / 255.0
            let g = CGFloat(dataPtr[offset + 1]) / 255.0
            let b = CGFloat(dataPtr[offset + 2]) / 255.0
            
            let distSq = (r - seedR) * (r - seedR) + (g - seedG) * (g - seedG) + (b - seedB) * (b - seedB)
            
            if distSq <= tolSq {
                maskData[cy * width + cx] = 255
                
                // Visit 8-connected neighbors
                for i in 0..<8 {
                    let nx = cx + dx[i]
                    let ny = cy + dy[i]
                    if nx >= 0, nx < width, ny >= 0, ny < height {
                        let nIdx = ny * width + nx
                        if !visited[nIdx] {
                            visited[nIdx] = true
                            queue.append((nx, ny))
                        }
                    }
                }
            }
        }
        
        // 4. Morphological closing to smooth edges (via dilation then erosion)
        morphologicalClose(&maskData, width: width, height: height, radius: 2)
        
        // 5. Convert mask data to UIImage
        return maskDataToUIImage(maskData, width: width, height: height)
    }
    
    // MARK: - Morphological Operations
    
    /// Simple morphological close (dilate + erode) on binary mask
    private func morphologicalClose(_ data: inout [UInt8], width: Int, height: Int, radius: Int) {
        let dilated = dilate(data, width: width, height: height, radius: radius)
        data = erode(dilated, width: width, height: height, radius: radius)
    }
    
    private func dilate(_ data: [UInt8], width: Int, height: Int, radius: Int) -> [UInt8] {
        var result = data
        for y in 0..<height {
            for x in 0..<width {
                if data[y * width + x] == 255 {
                    for dy in -radius...radius {
                        for dx in -radius...radius {
                            let nx = x + dx
                            let ny = y + dy
                            if nx >= 0, nx < width, ny >= 0, ny < height {
                                result[ny * width + nx] = 255
                            }
                        }
                    }
                }
            }
        }
        return result
    }
    
    private func erode(_ data: [UInt8], width: Int, height: Int, radius: Int) -> [UInt8] {
        var result = data
        for y in 0..<height {
            for x in 0..<width {
                if data[y * width + x] == 255 {
                    var allWhite = true
                    outerLoop: for dy in -radius...radius {
                        for dx in -radius...radius {
                            let nx = x + dx
                            let ny = y + dy
                            if nx < 0 || nx >= width || ny < 0 || ny >= height || data[ny * width + nx] == 0 {
                                allWhite = false
                                break outerLoop
                            }
                        }
                    }
                    if !allWhite { result[y * width + x] = 0 }
                }
            }
        }
        return result
    }
    
    // MARK: - Helpers
    
    private func maskDataToUIImage(_ data: [UInt8], width: Int, height: Int) -> UIImage? {
        var mutableData = data
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        return mutableData.withUnsafeMutableBufferPointer { buffer -> UIImage? in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ), let cgImage = context.makeImage() else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
    }
}

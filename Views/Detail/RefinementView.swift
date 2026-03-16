import SwiftUI

/// Interactive mask refinement view.
/// Users tap on blemish areas to mark them for removal, adjusting tolerance with a slider.
struct RefinementView: View {
    let originalImage: UIImage
    let aiMask: CIImage
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: (UIImage) -> Void
    
    @State private var tolerance: CGFloat = 0.15
    @State private var seedPoints: [(CGPoint, CGFloat)] = [] // (imageCoord, tolerance)
    @State private var previewScaleImage: UIImage? // Downsampled for performance
    @State private var previewImage: UIImage?
    @State private var isProcessing = false
    
    private let floodEngine = FloodFillEngine()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Image Canvas
                GeometryReader { geo in
                    ZStack {
                        // Checkerboard background to show transparency
                        CheckerboardView()
                        
                        // Preview image
                        if let preview = previewImage {
                            Image(uiImage: preview)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(uiImage: previewScaleImage ?? originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        
                        // Seed point markers
                        ForEach(Array(seedPoints.enumerated()), id: \.offset) { index, point in
                            let viewPoint = imageToViewCoord(point.0, in: geo.size)
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .position(viewPoint)
                        }
                        
                        // Processing overlay
                        if isProcessing {
                            Color.black.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, in: geo.size)
                    }
                }
                
                // MARK: - Controls
                VStack(spacing: 16) {
                    // Tolerance slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("容差 (实时预览模式)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(tolerance * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.itabinderGreen)
                        }
                        Slider(value: $tolerance, in: 0.01...0.5, step: 0.01)
                            .tint(.itabinderGreen)
                            .onChange(of: tolerance) {
                                Task { await generatePreview() }
                            }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: undoLastPoint) {
                            Label("撤销", systemImage: "arrow.uturn.backward")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                        .disabled(seedPoints.isEmpty)
                        
                        Button(action: clearAll) {
                            Label("重置", systemImage: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                        .disabled(seedPoints.isEmpty)
                        
                        Spacer()
                        
                        Text("\(seedPoints.count) 个选区")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("精细微调")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { finalizeRefinement() }
                        .fontWeight(.bold)
                        .foregroundColor(.itabinderGreen)
                        .disabled(isProcessing)
                }
            }
            .onAppear {
                preparePreviewImage()
            }
            .task {
                await generatePreview()
            }
        }
    }
    
    private func preparePreviewImage() {
        // Create 1024px preview for interaction speed
        let maxDim: CGFloat = 1024
        let aspect = originalImage.size.width / originalImage.size.height
        let targetSize: CGSize
        if aspect > 1 {
            targetSize = CGSize(width: maxDim, height: maxDim / aspect)
        } else {
            targetSize = CGSize(width: maxDim * aspect, height: maxDim)
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        previewScaleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // MARK: - Coordinate Mapping
    
    private func imageToViewCoord(_ imagePoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let imageSize = CGSize(width: originalImage.size.width, height: originalImage.size.height)
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let offsetX = (viewSize.width - scaledSize.width) / 2
        let offsetY = (viewSize.height - scaledSize.height) / 2
        
        return CGPoint(
            x: offsetX + imagePoint.x * scale,
            y: offsetY + imagePoint.y * scale
        )
    }
    
    private func viewToImageCoord(_ viewPoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let imageSize = CGSize(width: originalImage.size.width, height: originalImage.size.height)
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let offsetX = (viewSize.width - scaledSize.width) / 2
        let offsetY = (viewSize.height - scaledSize.height) / 2
        
        return CGPoint(
            x: (viewPoint.x - offsetX) / scale,
            y: (viewPoint.y - offsetY) / scale
        )
    }
    
    // MARK: - Actions
    
    private func handleTap(at location: CGPoint, in viewSize: CGSize) {
        let imageCoord = viewToImageCoord(location, in: viewSize)
        
        // Validate the point is within image bounds
        guard imageCoord.x >= 0, imageCoord.x < originalImage.size.width,
              imageCoord.y >= 0, imageCoord.y < originalImage.size.height else { return }
        
        HapticManager.shared.impact(.light)
        seedPoints.append((imageCoord, tolerance))
        
        Task { await generatePreview() }
    }
    
    private func undoLastPoint() {
        guard !seedPoints.isEmpty else { return }
        HapticManager.shared.impact(.light)
        seedPoints.removeLast()
        Task { await generatePreview() }
    }
    
    private func clearAll() {
        HapticManager.shared.impact(.medium)
        seedPoints.removeAll()
        Task { await generatePreview() }
    }
    
    private func generatePreview() async {
        let capturedSeedPoints = seedPoints
        let capturedPreviewImage = previewScaleImage ?? originalImage
        let capturedOriginalImage = originalImage
        let capturedAIMask = aiMask
        
        // During real-time interaction, use downsampled image
        let result = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let cgImage = capturedPreviewImage.cgImage else { return nil }
            let originalCI = CIImage(cgImage: cgImage)
            
            if capturedSeedPoints.isEmpty {
                return CompositingPipeline.applySimpleMask(
                    originalImage: originalCI,
                    mask: capturedAIMask,
                    featherRadius: 0.5,
                    scale: capturedPreviewImage.scale,
                    orientation: capturedPreviewImage.imageOrientation
                )
            }
            
            let engine = FloodFillEngine()
            let previewSize = capturedPreviewImage.size
            let originalSize = capturedOriginalImage.size
            let scaleX = previewSize.width / originalSize.width
            let scaleY = previewSize.height / originalSize.height
            
            var combinedMaskData = [UInt8](repeating: 0, count: cgImage.width * cgImage.height)
            
            for (point, tol) in capturedSeedPoints {
                // Map point from original image space to preview space
                let scaledPoint = CGPoint(x: point.x * scaleX, y: point.y * scaleY)
                if let singleMask = engine.generateFloodMask(from: capturedPreviewImage, seedPoint: scaledPoint, tolerance: tol) {
                    if let singleCG = singleMask.cgImage,
                       let singleData = singleCG.dataProvider?.data,
                       let ptr = CFDataGetBytePtr(singleData) {
                        for i in 0..<combinedMaskData.count {
                            if ptr[i] > 0 { combinedMaskData[i] = 255 }
                        }
                    }
                }
            }
            
            let colorSpace = CGColorSpaceCreateDeviceGray()
            guard let maskCG = combinedMaskData.withUnsafeMutableBufferPointer({ buffer -> CGImage? in
                guard let maskContext = CGContext(
                    data: buffer.baseAddress,
                    width: cgImage.width,
                    height: cgImage.height,
                    bitsPerComponent: 8,
                    bytesPerRow: cgImage.width,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                ) else { return nil }
                return maskContext.makeImage()
            }) else { return nil }
            
            let floodCIMask = CIImage(cgImage: maskCG)
            
            return CompositingPipeline.applyRefinement(
                originalImage: originalCI,
                aiMask: capturedAIMask,
                floodMask: floodCIMask,
                featherRadius: 0.5
            )
        }.value
        
        await MainActor.run {
            previewImage = result
            isProcessing = false
        }
    }
    
    private func finalizeRefinement() {
        isProcessing = true
        
        Task {
            let capturedSeedPoints = seedPoints
            let capturedOriginalImage = originalImage
            let capturedAIMask = aiMask
            
            // Final high-res processing
            let finalResult = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                guard let cgImage = capturedOriginalImage.cgImage else { return nil }
                let originalCI = CIImage(cgImage: cgImage)
                
                if capturedSeedPoints.isEmpty {
                    return CompositingPipeline.applySimpleMask(
                        originalImage: originalCI,
                        mask: capturedAIMask,
                        featherRadius: 0.5,
                        scale: capturedOriginalImage.scale,
                        orientation: capturedOriginalImage.imageOrientation
                    )
                }
                
                let engine = FloodFillEngine()
                var combinedMaskData = [UInt8](repeating: 0, count: cgImage.width * cgImage.height)
                
                for (point, tol) in capturedSeedPoints {
                    if let singleMask = engine.generateFloodMask(from: capturedOriginalImage, seedPoint: point, tolerance: tol) {
                        if let singleCG = singleMask.cgImage,
                           let singleData = singleCG.dataProvider?.data,
                           let ptr = CFDataGetBytePtr(singleData) {
                            for i in 0..<combinedMaskData.count {
                                if ptr[i] > 0 { combinedMaskData[i] = 255 }
                            }
                        }
                    }
                }
                
                let colorSpace = CGColorSpaceCreateDeviceGray()
                guard let maskCG = combinedMaskData.withUnsafeMutableBufferPointer({ buffer -> CGImage? in
                    guard let maskContext = CGContext(
                        data: buffer.baseAddress,
                        width: cgImage.width,
                        height: cgImage.height,
                        bitsPerComponent: 8,
                        bytesPerRow: cgImage.width,
                        space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.none.rawValue
                    ) else { return nil }
                    return maskContext.makeImage()
                }) else { return nil }
                
                let floodCIMask = CIImage(cgImage: maskCG)
                
                return CompositingPipeline.applyRefinement(
                    originalImage: originalCI,
                    aiMask: capturedAIMask,
                    floodMask: floodCIMask,
                    featherRadius: 0.5
                )
            }.value
            
            await MainActor.run {
                if let final = finalResult {
                    HapticManager.shared.notification(.success)
                    onComplete(final)
                    dismiss()
                }
                isProcessing = false
            }
        }
    }
}

// MARK: - Checkerboard Background (shows transparency)

struct CheckerboardView: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 10
            for row in 0..<Int(size.height / tileSize) + 1 {
                for col in 0..<Int(size.width / tileSize) + 1 {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? .white : Color(white: 0.9))
                    )
                }
            }
        }
    }
}

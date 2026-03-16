import SwiftUI

/// Post-capture processing view with cropping and background removal options
struct CaptureProcessingView: View {
    let capturedImage: UIImage
    var onComplete: (UIImage) -> Void
    var onRetake: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showRefinement = false
    @State private var processedImage: UIImage?
    @State private var normalizedImage: UIImage?
    @State private var isProcessingAI = false
    @State private var aiMask: CIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top controls (Native-style back button)
                HStack {
                    Button(action: { onRetake() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                
                // Preview area
                ZStack {
                    Image(uiImage: processedImage ?? capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if isProcessingAI {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                            Text("AI 识别中...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            processBackgroundRemoval()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 24))
                                Text("抠图")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        }
                        .disabled(isProcessingAI)
                        
                        if let _ = aiMask {
                            Button(action: {
                                HapticManager.shared.impact(.medium)
                                showRefinement = true
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "crop")
                                        .font(.system(size: 24))
                                    Text("精修")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Confirm button (Centered)
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.notification(.success)
                            onComplete(processedImage ?? capturedImage)
                        }) {
                            Text("使用照片")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 48)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
            }
        }
        .fullScreenCover(isPresented: $showRefinement) {
            if let mask = aiMask {
                RefinementView(
                    originalImage: normalizedImage ?? capturedImage,
                    aiMask: mask
                ) { refinedImage in
                    processedImage = refinedImage
                }
            }
        }
    }
    
    private func processBackgroundRemoval() {
        isProcessingAI = true
        
        Task {
            let result = await Task.detached(priority: .userInitiated) { () -> (UIImage?, CIImage?, UIImage?) in
                // Normalize image orientation first to avoid coordinate mismatches
                guard let normalizedImage = capturedImage.normalized(),
                      let cgImage = normalizedImage.cgImage else { return (nil, nil, nil) }
                
                let ciImage = CIImage(cgImage: cgImage)
                
                // Generate AI mask
                guard let mask = ImageClassificationService.shared.generateMask(for: ciImage) else {
                    return (nil, nil, nil)
                }
                
                // Apply mask
                let processed = CompositingPipeline.applySimpleMask(
                    originalImage: ciImage,
                    mask: mask,
                    featherRadius: 0.5,
                    scale: normalizedImage.scale,
                    orientation: .up
                )
                
                return (processed, mask, normalizedImage)
            }.value
            
            await MainActor.run {
                let (processed, mask, normalized) = result
                if let processed = processed, let mask = mask {
                    processedImage = processed
                    aiMask = mask
                    normalizedImage = normalized
                    HapticManager.shared.notification(.success)
                }
                isProcessingAI = false
            }
        }
    }
}

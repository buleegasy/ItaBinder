import SwiftUI

struct AsyncDisplayImage: View {
    let itemID: String
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.secondary.opacity(0.1)
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading High-Res...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard image == nil else { return }
        
        // 1. Check Cache first
        if let cached = ImageCache.shared.getImage(for: itemID, type: .display) {
            self.image = cached
            return
        }
        
        isLoading = true
        
        // 2. Load from disk and cache if not found
        let loadedImage = await Task.detached(priority: .medium) {
            return ImageStorageManager.shared.load(for: itemID, type: .display)
        }.value
        
        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
            if let loadedImage = loadedImage {
                ImageCache.shared.cacheImage(loadedImage, for: itemID, type: .display)
            }
        }
    }
}

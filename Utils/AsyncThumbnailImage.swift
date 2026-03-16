import SwiftUI

struct AsyncThumbnailImage: View {
    let itemID: String
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.1)
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "photo")
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
        
        // 1. Check Cache first (Synchronous on MainActor or fast enough)
        if let cached = ImageCache.shared.getImage(for: itemID, type: .thumb) {
            self.image = cached
            return
        }
        
        isLoading = true
        
        // 2. Load from disk and cache if not found
        let loadedImage = await Task.detached(priority: .userInitiated) {
            return ImageStorageManager.shared.load(for: itemID, type: .thumb)
        }.value
        
        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
            if let loadedImage = loadedImage {
                ImageCache.shared.cacheImage(loadedImage, for: itemID, type: .thumb)
            }
        }
    }
}

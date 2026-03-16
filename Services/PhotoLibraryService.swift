import Photos
import UIKit

@Observable
final class PhotoLibraryService {
    var recentAssets: [PHAsset] = []
    private let imageManager = PHCachingImageManager()
    
    func requestPermissionAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            if status == .authorized || status == .limited {
                self?.fetchRecentPhotos()
            }
        }
    }
    
    private func fetchRecentPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 30
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var fetched: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            fetched.append(asset)
        }
        
        Task { @MainActor in
            self.recentAssets = fetched
        }
    }
    
    func fetchThumbnail(for asset: PHAsset, size: CGSize = CGSize(width: 200, height: 200), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    
    func loadImageData(for asset: PHAsset) async -> Data? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}

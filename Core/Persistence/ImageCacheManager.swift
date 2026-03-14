import Foundation
import UIKit

/// A thread-safe, memory and disk-based image caching system.
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // Memory Cache: 
    // NSCache handles eviction automatically under memory pressure (LRU-like).
    private let memoryCache = NSCache<NSString, UIImage>()
    
    private init() {
        // Limit memory cache to avoid OOM
        memoryCache.countLimit = 100 // Cache up to 100 recent images
        memoryCache.totalCostLimit = 1024 * 1024 * 50 // Approx 50MB
    }
    
    /// Retrieves an image from the cache (Memory -> Disk).
    func getImage(for itemID: String, type: ImageStorageManager.ImageType) -> UIImage? {
        let key = cacheKey(for: itemID, type: type)
        
        // 1. Check Memory tier
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // 2. Check Disk tier (via ImageStorageManager)
        if let diskImage = ImageStorageManager.shared.load(for: itemID, type: type) {
            // Found on disk, promote to memory cache for faster future access
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: imageSize(diskImage))
            return diskImage
        }
        
        return nil
    }
    
    /// Caches an image in both memory and disk.
    func cacheImage(_ image: UIImage, for itemID: String, type: ImageStorageManager.ImageType) {
        let key = cacheKey(for: itemID, type: type)
        
        // Update Memory
        memoryCache.setObject(image, forKey: key as NSString, cost: imageSize(image))
        
        // Disk storage is handled during the import/downsampling phase by ImageStorageManager.
        // This function primarily ensures memory consistency.
    }
    
    // MARK: - Helpers
    
    private func cacheKey(for itemID: String, type: ImageStorageManager.ImageType) -> String {
        "\(itemID)_\(type.rawValue)"
    }
    
    private func imageSize(_ image: UIImage) -> Int {
        let bytesPerRow = Int(image.size.width) * 4
        return bytesPerRow * Int(image.size.height)
    }
    
    // MARK: - LRU & Eviction
    
    /// Explicitly clear memory cache.
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /// Evict from disk based on a maintenance strategy (e.g. date-based or size-based).
    /// Implementation calls into ImageStorageManager for folder-level cleaning.
    func performMaintenance(validIDs: Set<String>) {
        ImageStorageManager.shared.cleanupOrphanedFolders(validIDs: validIDs)
    }
}

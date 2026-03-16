import Foundation
import SwiftUI
import Combine

@Observable
final class SettingsViewModel {
    // Persistent settings
    @ObservationIgnored @AppStorage("isiCloudSyncEnabled") var isiCloudSyncEnabled: Bool = true
    @ObservationIgnored @AppStorage("isWatermarkEnabled") var isWatermarkEnabled: Bool = true
    
    // UI State
    var cacheSize: String = "Calculating..."
    var isClearingCache = false
    
    init() {
        updateCacheSize()
    }
    
    /// Calculates the size of the local image storage directory.
    func updateCacheSize() {
        Task {
            let size = await calculateDiskUsage()
            await MainActor.run {
                self.cacheSize = size
            }
        }
    }
    
    func clearCache() {
        isClearingCache = true
        Task {
            // Clear memory cache
            ImageCache.shared.clearMemoryCache()
            
            // In a real app, we would selectively clear 'thumb' and 'display' folders
            // while keeping 'original' images if they are the primary source.
            // For this exercise, we keep it simple.
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            
            await MainActor.run {
                self.isClearingCache = false
                updateCacheSize()
            }
        }
    }
    
    private func calculateDiskUsage() async -> String {
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let imagesDir = appSupportDir.appendingPathComponent("images")
        
        var totalSize: Int64 = 0
        let enumerator = fileManager.enumerator(at: imagesDir, includingPropertiesForKeys: [.fileSizeKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues?.fileSize ?? 0)
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

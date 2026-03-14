import Foundation
import UIKit

final class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    
    enum ImageType: String {
        case thumb = "thumb.jpg"
        case display = "display.jpg"
        case original = "original.jpg"
    }
    
    private var baseDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ItaBinderImages", isDirectory: true)
    }
    
    private init() {
        createBaseDirectoryIfNeeded()
    }
    
    private func createBaseDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Internal API
    
    func createFolder(for itemID: String) throws -> URL {
        let folderURL = baseDirectory.appendingPathComponent(itemID, isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
    
    func save(data: Data, for itemID: String, type: ImageType) throws -> URL {
        let folderURL = try createFolder(for: itemID)
        let fileURL = folderURL.appendingPathComponent(type.rawValue)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    func load(for itemID: String, type: ImageType) -> UIImage? {
        let fileURL = baseDirectory.appendingPathComponent(itemID).appendingPathComponent(type.rawValue)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    func getURL(for itemID: String, type: ImageType) -> URL? {
        let fileURL = baseDirectory.appendingPathComponent(itemID).appendingPathComponent(type.rawValue)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func deleteFolder(for itemID: String) {
        let folderURL = baseDirectory.appendingPathComponent(itemID)
        try? fileManager.removeItem(at: folderURL)
    }
    
    // MARK: - Cleanup Strategy
    
    /// Deletes all folders in the base directory that aren't in the provided list of valid IDs.
    /// This is a maintenance function to cleanup orphaned files.
    func cleanupOrphanedFolders(validIDs: Set<String>) {
        do {
            let itemFolders = try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
            for folderURL in itemFolders {
                let folderName = folderURL.lastPathComponent
                if !validIDs.contains(folderName) {
                    try? fileManager.removeItem(at: folderURL)
                }
            }
        } catch {
            print("Cleanup failed: \(error)")
        }
    }
}

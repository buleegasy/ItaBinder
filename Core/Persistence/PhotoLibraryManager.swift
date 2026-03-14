import Foundation
import Photos
import UIKit

final class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    private init() {}
    
    enum PhotoLibraryError: LocalizedError {
        case notAuthorized
        case saveFailed(Error?)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Photo Library access is required to save images."
            case .saveFailed(let error):
                return "Failed to save image: \(error?.localizedDescription ?? "Unknown error")"
            }
        }
    }
    
    /// Requests authorization and saves an image to the user's photo library.
    func saveImageToLibrary(_ image: UIImage) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            try await performSave(image)
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                try await performSave(image)
            } else {
                throw PhotoLibraryError.notAuthorized
            }
        default:
            throw PhotoLibraryError.notAuthorized
        }
    }
    
    private func performSave(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

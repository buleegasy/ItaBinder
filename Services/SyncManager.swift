import Foundation
import SwiftData
import Combine
import CoreData

/// Manages CloudKit synchronization events and provides status updates to the UI.
@Observable
final class SyncManager {
    static let shared = SyncManager()
    
    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupCloudKitNotifications()
    }
    
    private func setupCloudKitNotifications() {
        // Monitor SwiftData/CoreData CloudKit events
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        Task { @MainActor in
            switch event.type {
            case .setup, .import, .export:
                self.isSyncing = event.endDate == nil
            @unknown default:
                break
            }
            
            if let error = event.error {
                self.syncError = error.localizedDescription
            } else if event.endDate != nil {
                self.lastSyncDate = event.endDate
                self.syncError = nil
            }
        }
    }
    
    /// Manually triggers a sync if needed (though CloudKit is usually automatic)
    func triggerManualSync() {
        // SwiftData/CloudKit handles this automatically, but we can provide UI hooks here.
    }
}

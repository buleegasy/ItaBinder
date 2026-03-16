import SwiftUI
import Observation

@Observable
final class MainNavigationState {
    var isTabBarVisible: Bool = true
    var isEditMode: Bool = false
    var selectedItemIDs: Set<UUID> = []
}


import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Use for physical-feeling clicks (e.g., button presses, toggles)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Use for light state changes (e.g., tab switching, scroll snapping)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Use for alerts and status changes (e.g., success, error)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

import Foundation
import CoreMotion

/// Gyroscope-based guidance for anti-glare badge capture.
/// Monitors device pitch to maintain the optimal angle range (-15° to -25°)
/// where overhead light reflections are deflected away from the lens.
@Observable
final class CaptureGuideManager {
    
    enum GuideState: Equatable {
        case unknown
        case tooFlat       // 手机太平 (pitch > -15°)
        case tooSteep      // 手机太陡 (pitch < -25°)
        case ready         // 黄金角度区间
    }
    
    private(set) var state: GuideState = .unknown
    private(set) var currentPitch: Double = 0.0 // in degrees
    
    /// Normalized stability score (0.0~1.0). 1.0 = perfectly stable.
    private(set) var stabilityScore: Double = 0.0
    
    private let motionManager = CMMotionManager()
    private var pitchHistory: [Double] = []
    private let historySize = 10
    
    // MARK: - Golden angle constants
    private let minPitch: Double = -25.0  // Maximum allowed tilt (more steep)
    private let maxPitch: Double = -15.0  // Minimum allowed tilt (more flat)
    private let stabilityThreshold: Double = 1.5 // Max stddev for "stable"
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            state = .unknown
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 20 // 20Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion else { return }
            
            let pitchDegrees = motion.attitude.pitch * 180.0 / .pi
            self.currentPitch = pitchDegrees
            
            // Update pitch history for stability calculation
            self.pitchHistory.append(pitchDegrees)
            if self.pitchHistory.count > self.historySize {
                self.pitchHistory.removeFirst()
            }
            
            // Calculate stability
            self.stabilityScore = self.calculateStability()
            
            // Determine guide state
            if pitchDegrees > self.maxPitch {
                self.state = .tooFlat
            } else if pitchDegrees < self.minPitch {
                self.state = .tooSteep
            } else {
                self.state = .ready
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        state = .unknown
        pitchHistory.removeAll()
    }
    
    /// Whether the device is stable enough AND at the correct angle to take a high-quality shot.
    var isReadyToCapture: Bool {
        state == .ready && stabilityScore > 0.7
    }
    
    // MARK: - Private
    
    private func calculateStability() -> Double {
        guard pitchHistory.count >= 3 else { return 0.0 }
        
        let mean = pitchHistory.reduce(0, +) / Double(pitchHistory.count)
        let variance = pitchHistory.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(pitchHistory.count)
        let stddev = sqrt(variance)
        
        // Map stddev to 0~1 score. Lower stddev = higher stability.
        return max(0, min(1, 1.0 - stddev / stabilityThreshold))
    }
}

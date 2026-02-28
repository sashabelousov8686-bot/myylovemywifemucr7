import UIKit

// MARK: - Haptic Feedback Manager

final class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        prepareAll()
    }
    
    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func light() {
        lightGenerator.impactOccurred()
    }
    
    func medium() {
        mediumGenerator.impactOccurred()
    }
    
    func heavy() {
        heavyGenerator.impactOccurred()
    }
    
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Trigger haptic at milestone thresholds
    func checkMilestone(oldValue: Double, newValue: Double, threshold: Double = 100_000) {
        let oldMilestone = Int(oldValue / threshold)
        let newMilestone = Int(newValue / threshold)
        if newMilestone > oldMilestone {
            heavy()
        }
    }
    
    /// Trigger haptic at year thresholds
    func checkYearMilestone(oldYears: Double, newYears: Double, interval: Double = 5) {
        let oldMilestone = Int(oldYears / interval)
        let newMilestone = Int(newYears / interval)
        if newMilestone != oldMilestone {
            medium()
        }
    }
}

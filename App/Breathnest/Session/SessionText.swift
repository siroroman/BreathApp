import BreathnestKit
import Foundation

/// The text of the Session screens, built from the String Catalog. The ViewModel holds none of it (ADR 0002).
enum SessionText {
    /// Time left as `m:ss`, rounded up so the display never shows 0:00 while time is left.
    static func remaining(_ duration: Duration) -> String {
        let total = Int((duration / .seconds(1)).rounded(.up))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    /// `Box breathing · 19 Cycles · 5:04`.
    static func summary(of exercise: Exercise, length: SessionLength) -> String {
        let cycles = length.cycleCount
        let total = ExerciseText.clock(length.totalLength)
        return String(localized: "session.summary \(ExerciseText.name(of: exercise)) \(cycles) \(total)")
    }
}

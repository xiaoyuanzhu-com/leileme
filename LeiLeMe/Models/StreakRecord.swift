import Foundation
import SwiftData

/// Persists streak state across app launches.
@Model
final class StreakRecord {
    /// Current consecutive-day streak count.
    var currentStreak: Int
    /// The last date (start of day) on which the user completed at least one measure.
    var lastActiveDate: Date
    /// Whether the grace period has been consumed for the current streak.
    var graceUsed: Bool

    init(
        currentStreak: Int = 0,
        lastActiveDate: Date = .distantPast,
        graceUsed: Bool = false
    ) {
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.graceUsed = graceUsed
    }
}

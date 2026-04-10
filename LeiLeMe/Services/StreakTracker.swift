import Foundation
import SwiftData

/// Tracks consecutive-day streaks with a 1-day grace period.
///
/// Rules:
/// - A day counts if at least one measure was completed.
/// - Missing 1 day uses the grace period (streak continues but graceUsed = true).
/// - Missing 2+ consecutive days resets the streak to 0.
/// - Streak is recalculated from persisted StreakRecord whenever the app refreshes.
@Observable
final class StreakTracker {
    private var modelContext: ModelContext

    /// Current streak count (read from persisted record).
    private(set) var currentStreak: Int = 0
    /// Whether the grace period has been consumed for this streak.
    private(set) var graceUsed: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStreak()
    }

    // MARK: - Public API

    /// Call this whenever a measure is completed or when the home page appears.
    /// Reads the assessment history and updates the streak accordingly.
    func refresh(assessments: [DailyAssessment]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if today has at least one measure
        let todayHasData = assessments.contains { assessment in
            calendar.startOfDay(for: assessment.date) == today && hasAnyMeasure(assessment)
        }

        let record = fetchOrCreateRecord()

        // If the last active date is already today, nothing to update
        let lastActive = calendar.startOfDay(for: record.lastActiveDate)
        if lastActive == today {
            currentStreak = record.currentStreak
            graceUsed = record.graceUsed
            return
        }

        if todayHasData {
            let daysSinceLastActive = calendar.dateComponents([.day], from: lastActive, to: today).day ?? Int.max

            if lastActive == .distantPast || daysSinceLastActive < 0 {
                // First ever activity
                record.currentStreak = 1
                record.graceUsed = false
            } else if daysSinceLastActive == 1 {
                // Consecutive day — no gap
                record.currentStreak += 1
                // Grace flag stays as-is (it could have been used on a prior gap)
            } else if daysSinceLastActive == 2 {
                // 1 day missed — use grace period if not already used
                if !record.graceUsed {
                    record.currentStreak += 1
                    record.graceUsed = true
                } else {
                    // Grace already used, 1 more missed day means 2 total gap — reset
                    record.currentStreak = 1
                    record.graceUsed = false
                }
            } else {
                // 2+ days missed — reset
                record.currentStreak = 1
                record.graceUsed = false
            }

            record.lastActiveDate = today
            try? modelContext.save()
        } else {
            // Today has no data yet. Check if the streak is still alive.
            let daysSinceLastActive = calendar.dateComponents([.day], from: lastActive, to: today).day ?? Int.max

            if lastActive == .distantPast {
                record.currentStreak = 0
            } else if daysSinceLastActive <= 1 {
                // Either today or yesterday was active — streak is alive
            } else if daysSinceLastActive == 2 && !record.graceUsed {
                // Grace period covers today (not yet expired)
            } else {
                // Streak broken
                record.currentStreak = 0
                record.graceUsed = false
                try? modelContext.save()
            }
        }

        currentStreak = record.currentStreak
        graceUsed = record.graceUsed
    }

    /// Returns a milestone message if the current streak matches a milestone, else nil.
    var milestoneMessage: String? {
        switch currentStreak {
        case 3:  return "Getting started!"
        case 7:  return "Baseline complete!"
        case 14: return "Two weeks strong!"
        case 30: return "One month — incredible!"
        default: return nil
        }
    }

    // MARK: - Private helpers

    private func hasAnyMeasure(_ assessment: DailyAssessment) -> Bool {
        Measure.allCases.contains { assessment.value(for: $0) != nil }
    }

    private func loadStreak() {
        let record = fetchOrCreateRecord()
        currentStreak = record.currentStreak
        graceUsed = record.graceUsed
    }

    private func fetchOrCreateRecord() -> StreakRecord {
        let descriptor = FetchDescriptor<StreakRecord>()
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            return existing
        }
        let newRecord = StreakRecord()
        modelContext.insert(newRecord)
        try? modelContext.save()
        return newRecord
    }
}

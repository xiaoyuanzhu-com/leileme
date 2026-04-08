import Foundation
import SwiftData

/// Computes rolling 7-day baselines across all assessment dimensions.
final class BaselineEngine {

    struct BaselineSnapshot {
        var hrvBaseline: Double?
        var rhrBaseline: Double?
        var sleepDurationBaseline: Double?
        var tapFrequencyBaseline: Double?
        var rhythmStabilityBaseline: Double?
        var reactionTimeBaseline: Double?
        var reactionConsistencyBaseline: Double?
        var sleepQualityBaseline: Double?
        var sorenessBaseline: Double?
        var energyBaseline: Double?
        /// Number of days contributing to the baseline (max 7).
        var dayCount: Int
    }

    /// Compute a baseline from the most recent 7 days of assessments.
    ///
    /// - Parameter assessments: All available assessments (need not be sorted).
    /// - Returns: A snapshot averaging each dimension over the last 7 calendar days.
    func computeBaseline(from assessments: [DailyAssessment]) -> BaselineSnapshot {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else {
            return emptySnapshot()
        }

        let recent = assessments.filter { $0.date >= cutoff }

        if recent.isEmpty {
            return emptySnapshot()
        }

        // Collectors — accumulate non-nil values per dimension.
        var hrvValues: [Double] = []
        var rhrValues: [Double] = []
        var sleepDurationValues: [Double] = []
        var tapFreqValues: [Double] = []
        var rhythmValues: [Double] = []
        var reactionValues: [Double] = []
        var reactionConsistencyValues: [Double] = []
        var sleepQualityValues: [Double] = []
        var sorenessValues: [Double] = []
        var energyValues: [Double] = []

        for assessment in recent {
            // HealthKit
            if let hk = assessment.healthKitData {
                if let v = hk.hrvRMSSD { hrvValues.append(v) }
                if let v = hk.restingHeartRate { rhrValues.append(v) }
                if let v = hk.sleepDuration { sleepDurationValues.append(v) }
            }

            // Tap test — average of the two round frequencies
            if let tap = assessment.tapTestResult {
                let avgFreq = (tap.round1Frequency + tap.round2Frequency) / 2.0
                tapFreqValues.append(avgFreq)
                rhythmValues.append(tap.rhythmStability)
            }

            // Reaction time
            if let rt = assessment.reactionTimeResult {
                reactionValues.append(rt.averageMs)
                reactionConsistencyValues.append(rt.standardDeviationMs)
            }

            // Subjective
            if let sub = assessment.subjectiveAssessment {
                sleepQualityValues.append(Double(sub.sleepQuality))
                sorenessValues.append(Double(sub.muscleSoreness))
                energyValues.append(Double(sub.energyLevel))
            }
        }

        return BaselineSnapshot(
            hrvBaseline: Self.average(of: hrvValues),
            rhrBaseline: Self.average(of: rhrValues),
            sleepDurationBaseline: Self.average(of: sleepDurationValues),
            tapFrequencyBaseline: Self.average(of: tapFreqValues),
            rhythmStabilityBaseline: Self.average(of: rhythmValues),
            reactionTimeBaseline: Self.average(of: reactionValues),
            reactionConsistencyBaseline: Self.average(of: reactionConsistencyValues),
            sleepQualityBaseline: Self.average(of: sleepQualityValues),
            sorenessBaseline: Self.average(of: sorenessValues),
            energyBaseline: Self.average(of: energyValues),
            dayCount: recent.count
        )
    }

    // MARK: - Helpers

    private func emptySnapshot() -> BaselineSnapshot {
        BaselineSnapshot(
            hrvBaseline: nil,
            rhrBaseline: nil,
            sleepDurationBaseline: nil,
            tapFrequencyBaseline: nil,
            rhythmStabilityBaseline: nil,
            reactionTimeBaseline: nil,
            reactionConsistencyBaseline: nil,
            sleepQualityBaseline: nil,
            sorenessBaseline: nil,
            energyBaseline: nil,
            dayCount: 0
        )
    }

    private static func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

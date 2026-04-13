import Foundation

/// Computes a composite recovery score from today's assessment data compared against baseline.
struct RecoveryScoreEngine {

    struct Result {
        let score: Double          // 0-100+
        let status: RecoveryStatus
        let headline: String
        let detail: String
        let availableDimensions: Int
        let totalDimensions: Int
    }

    /// Dimension descriptor used internally.
    private struct Dimension {
        let name: String
        let todayValue: Double?
        let baselineValue: Double?
        let weight: Double
        let higherIsBetter: Bool
    }

    /// Total number of scored dimensions.
    static let dimensionCount = 10

    // MARK: - Public

    static func evaluate(
        assessment: DailyAssessment,
        baseline: BaselineEngine.BaselineSnapshot
    ) -> Result {

        // During baseline building (< 3 days), we cannot give a meaningful score.
        guard baseline.dayCount >= 3 else {
            let userDay = max(baseline.dayCount, 1) + 1
            let headline: String
            let detail: String
            switch userDay {
            case 1...2:
                headline = String(localized: "recovery.engine.gettingToKnow.headline")
                detail = String(localized: "recovery.engine.gettingToKnow.detail \(userDay)")
            case 3:
                headline = String(localized: "recovery.engine.dayN.headline \(userDay)")
                detail = String(localized: "recovery.engine.dayN.detail")
            default:
                headline = String(localized: "recovery.engine.dayNof7.headline \(userDay)")
                detail = String(localized: "recovery.engine.dayNof7.detail")
            }
            return Result(
                score: 0,
                status: .neutral,
                headline: headline,
                detail: detail,
                availableDimensions: 0,
                totalDimensions: dimensionCount
            )
        }

        let tapFreqToday: Double? = {
            guard let tap = assessment.tapTestResult else { return nil }
            return (tap.round1Frequency + tap.round2Frequency) / 2.0
        }()

        let dims: [Dimension] = [
            Dimension(name: "Grip Strength",
                      todayValue: assessment.value(for: .gripStrength),
                      baselineValue: baseline.gripStrengthBaseline,
                      weight: 20, higherIsBetter: true),
            Dimension(name: "HRV",
                      todayValue: assessment.healthKitData?.hrvSDNN,
                      baselineValue: baseline.hrvBaseline,
                      weight: 20, higherIsBetter: true),
            Dimension(name: "Resting HR",
                      todayValue: assessment.healthKitData?.restingHeartRate,
                      baselineValue: baseline.rhrBaseline,
                      weight: 10, higherIsBetter: false),
            Dimension(name: "Tap Frequency",
                      todayValue: tapFreqToday,
                      baselineValue: baseline.tapFrequencyBaseline,
                      weight: 15, higherIsBetter: true),
            Dimension(name: "Tap Stability",
                      todayValue: assessment.tapTestResult?.rhythmStability,
                      baselineValue: baseline.rhythmStabilityBaseline,
                      weight: 5, higherIsBetter: false),
            Dimension(name: "Reaction Time",
                      todayValue: assessment.reactionTimeResult?.averageMs,
                      baselineValue: baseline.reactionTimeBaseline,
                      weight: 15, higherIsBetter: false),
            Dimension(name: "Sleep Duration",
                      todayValue: assessment.healthKitData?.sleepDuration,
                      baselineValue: baseline.sleepDurationBaseline,
                      weight: 10, higherIsBetter: true),
            Dimension(name: "Sleep Quality",
                      todayValue: assessment.subjectiveAssessment.map { Double($0.sleepQuality) },
                      baselineValue: baseline.sleepQualityBaseline,
                      weight: 5, higherIsBetter: true),
            Dimension(name: "Soreness",
                      todayValue: assessment.subjectiveAssessment.map { Double($0.muscleSoreness) },
                      baselineValue: baseline.sorenessBaseline,
                      weight: 10, higherIsBetter: true),
            Dimension(name: "Energy",
                      todayValue: assessment.subjectiveAssessment.map { Double($0.energyLevel) },
                      baselineValue: baseline.energyBaseline,
                      weight: 10, higherIsBetter: true),
        ]

        // Filter to dimensions where both today and baseline are available.
        let available = dims.filter { $0.todayValue != nil && $0.baselineValue != nil }

        guard !available.isEmpty else {
            return Result(
                score: 0,
                status: .neutral,
                headline: String(localized: "recovery.notEnough.headline"),
                detail: String(localized: "recovery.notEnough.detail"),
                availableDimensions: 0,
                totalDimensions: dims.count
            )
        }

        // Redistribute weights proportionally.
        let totalWeight = available.reduce(0.0) { $0 + $1.weight }

        var weightedSum: Double = 0

        for dim in available {
            let today = dim.todayValue!
            let base = dim.baselineValue!
            guard base > 0 else { continue }

            let ratio: Double
            if dim.higherIsBetter {
                ratio = today / base          // > 1 means better
            } else {
                ratio = base / today          // > 1 means better (lower today is good)
            }

            // Convert ratio to a 0-100+ scale: 1.0 = 100 (at baseline).
            let dimScore = ratio * 100.0

            let normalizedWeight = dim.weight / totalWeight
            weightedSum += dimScore * normalizedWeight
        }

        // Clamp display to 0...120 to avoid absurd numbers.
        let finalScore = min(max(weightedSum, 0), 120)

        let status: RecoveryStatus
        let headline: String
        let detail: String

        switch finalScore {
        case 90...:
            status = .good
            headline = String(localized: "recovery.good.headline")
            detail = String(localized: "recovery.good.detail")
        case 70..<90:
            status = .moderate
            headline = String(localized: "recovery.moderate.headline")
            detail = String(localized: "recovery.moderate.detail")
        default:
            status = .needsAttention
            headline = String(localized: "recovery.needsAttention.headline")
            detail = String(localized: "recovery.needsAttention.detail")
        }

        return Result(
            score: finalScore,
            status: status,
            headline: headline,
            detail: detail,
            availableDimensions: available.count,
            totalDimensions: dims.count
        )
    }
}

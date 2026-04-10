import Foundation
import SwiftData
@testable import LeiLeMe

/// Helpers for creating test fixtures without needing a live SwiftData store.
enum TestHelpers {

    // MARK: - In-memory ModelContainer

    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: DailyAssessment.self,
                 HealthKitReading.self,
                 TapTestResult.self,
                 ReactionTimeResult.self,
                 SubjectiveAssessment.self,
                 StreakRecord.self,
            configurations: config
        )
    }

    // MARK: - Factory: DailyAssessment

    /// Create a DailyAssessment for `daysAgo` days before today's start-of-day.
    @MainActor
    static func makeAssessment(
        daysAgo: Int,
        hrv: Double? = nil,
        rhr: Double? = nil,
        sleepDuration: Double? = nil,
        tapR1Freq: Double? = nil,
        tapR2Freq: Double? = nil,
        rhythmStability: Double? = nil,
        reactionAvg: Double? = nil,
        reactionSD: Double? = nil,
        sleepQuality: Int? = nil,
        muscleSoreness: Int? = nil,
        energyLevel: Int? = nil,
        in context: ModelContext
    ) -> DailyAssessment {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
        let assessment = DailyAssessment(date: date)
        context.insert(assessment)

        // HealthKit
        if hrv != nil || rhr != nil || sleepDuration != nil {
            let hk = HealthKitReading(
                hrvSDNN: hrv,
                restingHeartRate: rhr,
                sleepDuration: sleepDuration
            )
            context.insert(hk)
            assessment.healthKitData = hk
        }

        // Tap test
        if let r1 = tapR1Freq, let r2 = tapR2Freq {
            let tap = TapTestResult(
                round1Taps: Int(r1 * 10),
                round2Taps: Int(r2 * 10),
                round1Frequency: r1,
                round2Frequency: r2,
                rhythmStability: rhythmStability ?? 0.1,
                fatigueDecay: r1 > 0 ? r2 / r1 : 1.0
            )
            context.insert(tap)
            assessment.tapTestResult = tap
        }

        // Reaction time
        if let avg = reactionAvg {
            let rt = ReactionTimeResult(
                reactionTimesMs: [avg, avg, avg],
                averageMs: avg,
                standardDeviationMs: reactionSD ?? 10,
                fastestMs: avg - 20,
                slowestMs: avg + 20
            )
            context.insert(rt)
            assessment.reactionTimeResult = rt
        }

        // Subjective
        if sleepQuality != nil || muscleSoreness != nil || energyLevel != nil {
            let sub = SubjectiveAssessment(
                sleepQuality: sleepQuality ?? 0,
                muscleSoreness: muscleSoreness ?? 0,
                energyLevel: energyLevel ?? 0
            )
            context.insert(sub)
            assessment.subjectiveAssessment = sub
        }

        try? context.save()
        return assessment
    }

    /// Create a fully-populated assessment with all 9 measures.
    @MainActor
    static func makeFullAssessment(
        daysAgo: Int,
        in context: ModelContext,
        hrv: Double = 45,
        rhr: Double = 60,
        sleepDuration: Double = 7.5,
        tapR1Freq: Double = 5.0,
        tapR2Freq: Double = 4.8,
        rhythmStability: Double = 0.12,
        reactionAvg: Double = 300,
        reactionSD: Double = 20,
        sleepQuality: Int = 4,
        muscleSoreness: Int = 4,
        energyLevel: Int = 4
    ) -> DailyAssessment {
        makeAssessment(
            daysAgo: daysAgo,
            hrv: hrv, rhr: rhr, sleepDuration: sleepDuration,
            tapR1Freq: tapR1Freq, tapR2Freq: tapR2Freq,
            rhythmStability: rhythmStability,
            reactionAvg: reactionAvg, reactionSD: reactionSD,
            sleepQuality: sleepQuality,
            muscleSoreness: muscleSoreness,
            energyLevel: energyLevel,
            in: context
        )
    }
}

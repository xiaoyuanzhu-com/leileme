import SwiftUI

struct ResultView: View {
    let assessment: DailyAssessment
    let baseline: BaselineEngine.BaselineSnapshot

    var body: some View {
        List {
            // HealthKit section
            Section {
                DimensionRow(
                    title: "HRV (RMSSD)",
                    todayValue: assessment.healthKitData?.hrvRMSSD,
                    baselineValue: baseline.hrvBaseline,
                    unit: "ms",
                    higherIsBetter: true,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Resting Heart Rate",
                    todayValue: assessment.healthKitData?.restingHeartRate,
                    baselineValue: baseline.rhrBaseline,
                    unit: "bpm",
                    higherIsBetter: false,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Sleep Duration",
                    todayValue: assessment.healthKitData?.sleepDuration,
                    baselineValue: baseline.sleepDurationBaseline,
                    unit: "hrs",
                    higherIsBetter: true,
                    formatString: "%.1f",
                    baselineDayCount: baseline.dayCount
                )
            } header: {
                Label("HealthKit", systemImage: "heart.fill")
            }

            // Tap Test section
            Section {
                DimensionRow(
                    title: "Tap Frequency",
                    todayValue: tapFrequencyToday,
                    baselineValue: baseline.tapFrequencyBaseline,
                    unit: "taps/s",
                    higherIsBetter: true,
                    formatString: "%.1f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Rhythm Stability",
                    todayValue: assessment.tapTestResult?.rhythmStability,
                    baselineValue: baseline.rhythmStabilityBaseline,
                    unit: "CV",
                    higherIsBetter: false,
                    formatString: "%.3f",
                    baselineDayCount: baseline.dayCount
                )
            } header: {
                Label("Tap Test", systemImage: "hand.tap.fill")
            }

            // Reaction Time section
            Section {
                DimensionRow(
                    title: "Avg Reaction Time",
                    todayValue: assessment.reactionTimeResult?.averageMs,
                    baselineValue: baseline.reactionTimeBaseline,
                    unit: "ms",
                    higherIsBetter: false,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Consistency (StdDev)",
                    todayValue: assessment.reactionTimeResult?.standardDeviationMs,
                    baselineValue: baseline.reactionConsistencyBaseline,
                    unit: "ms",
                    higherIsBetter: false,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )
            } header: {
                Label("Reaction Time", systemImage: "bolt.circle.fill")
            }

            // Subjective section
            Section {
                DimensionRow(
                    title: "Sleep Quality",
                    todayValue: assessment.subjectiveAssessment.map { Double($0.sleepQuality) },
                    baselineValue: baseline.sleepQualityBaseline,
                    unit: "/5",
                    higherIsBetter: true,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Muscle Soreness",
                    todayValue: assessment.subjectiveAssessment.map { Double($0.muscleSoreness) },
                    baselineValue: baseline.sorenessBaseline,
                    unit: "/5",
                    higherIsBetter: true,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )

                DimensionRow(
                    title: "Energy Level",
                    todayValue: assessment.subjectiveAssessment.map { Double($0.energyLevel) },
                    baselineValue: baseline.energyBaseline,
                    unit: "/5",
                    higherIsBetter: true,
                    formatString: "%.0f",
                    baselineDayCount: baseline.dayCount
                )
            } header: {
                Label("Subjective", systemImage: "heart.text.clipboard")
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Computed

    private var tapFrequencyToday: Double? {
        guard let tap = assessment.tapTestResult else { return nil }
        return (tap.round1Frequency + tap.round2Frequency) / 2.0
    }
}

#Preview {
    NavigationStack {
        ResultView(
            assessment: {
                let a = DailyAssessment(date: Date())
                a.healthKitData = HealthKitReading(
                    hrvRMSSD: 42,
                    restingHeartRate: 58,
                    sleepDuration: 7.5
                )
                a.tapTestResult = TapTestResult(
                    round1Taps: 45,
                    round2Taps: 43,
                    round1Frequency: 7.5,
                    round2Frequency: 7.2,
                    rhythmStability: 0.085,
                    fatigueDecay: 0.04
                )
                a.reactionTimeResult = ReactionTimeResult(
                    reactionTimesMs: [280, 265, 290, 275, 270],
                    averageMs: 276,
                    standardDeviationMs: 9.4,
                    fastestMs: 265,
                    slowestMs: 290
                )
                a.subjectiveAssessment = SubjectiveAssessment(
                    sleepQuality: 4,
                    muscleSoreness: 3,
                    energyLevel: 4
                )
                return a
            }(),
            baseline: BaselineEngine.BaselineSnapshot(
                hrvBaseline: 38,
                rhrBaseline: 62,
                sleepDurationBaseline: 7.2,
                tapFrequencyBaseline: 7.0,
                rhythmStabilityBaseline: 0.095,
                reactionTimeBaseline: 290,
                reactionConsistencyBaseline: 15,
                sleepQualityBaseline: 3.5,
                sorenessBaseline: 3.2,
                energyBaseline: 3.8,
                dayCount: 7
            )
        )
    }
}

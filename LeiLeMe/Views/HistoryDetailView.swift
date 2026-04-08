import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    let assessment: DailyAssessment
    let allAssessments: [DailyAssessment]

    private var baseline: BaselineEngine.BaselineSnapshot {
        // Compute baseline from assessments prior to this one
        let engine = BaselineEngine()
        let prior = allAssessments.filter { $0.date < assessment.date }
        return engine.computeBaseline(from: prior)
    }

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // HealthKit section
                    sectionCard(
                        title: "HealthKit",
                        icon: "heart.fill",
                        color: .wellnessRed
                    ) {
                        DimensionRow(
                            title: "HRV (RMSSD)",
                            icon: "waveform.path.ecg",
                            todayValue: assessment.healthKitData?.hrvRMSSD,
                            baselineValue: baseline.hrvBaseline,
                            unit: "ms",
                            higherIsBetter: true,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Resting Heart Rate",
                            icon: "heart.fill",
                            todayValue: assessment.healthKitData?.restingHeartRate,
                            baselineValue: baseline.rhrBaseline,
                            unit: "bpm",
                            higherIsBetter: false,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Sleep Duration",
                            icon: "bed.double.fill",
                            todayValue: assessment.healthKitData?.sleepDuration,
                            baselineValue: baseline.sleepDurationBaseline,
                            unit: "hrs",
                            higherIsBetter: true,
                            formatString: "%.1f",
                            baselineDayCount: baseline.dayCount
                        )
                    }

                    // Tap Test section
                    sectionCard(
                        title: "Tap Test",
                        icon: "hand.tap.fill",
                        color: .wellnessTeal
                    ) {
                        DimensionRow(
                            title: "Tap Frequency",
                            icon: "metronome.fill",
                            todayValue: tapFrequency,
                            baselineValue: baseline.tapFrequencyBaseline,
                            unit: "taps/s",
                            higherIsBetter: true,
                            formatString: "%.1f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Rhythm Stability",
                            icon: "waveform",
                            todayValue: assessment.tapTestResult?.rhythmStability,
                            baselineValue: baseline.rhythmStabilityBaseline,
                            unit: "CV",
                            higherIsBetter: false,
                            formatString: "%.3f",
                            baselineDayCount: baseline.dayCount
                        )
                    }

                    // Reaction Time section
                    sectionCard(
                        title: "Reaction Time",
                        icon: "bolt.circle.fill",
                        color: .wellnessGreen
                    ) {
                        DimensionRow(
                            title: "Avg Reaction Time",
                            icon: "bolt.fill",
                            todayValue: assessment.reactionTimeResult?.averageMs,
                            baselineValue: baseline.reactionTimeBaseline,
                            unit: "ms",
                            higherIsBetter: false,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Consistency (StdDev)",
                            icon: "chart.bar.fill",
                            todayValue: assessment.reactionTimeResult?.standardDeviationMs,
                            baselineValue: baseline.reactionConsistencyBaseline,
                            unit: "ms",
                            higherIsBetter: false,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )
                    }

                    // Subjective section
                    sectionCard(
                        title: "Subjective",
                        icon: "face.smiling",
                        color: .wellnessAmber
                    ) {
                        DimensionRow(
                            title: "Sleep Quality",
                            icon: "moon.fill",
                            todayValue: assessment.subjectiveAssessment.map { Double($0.sleepQuality) },
                            baselineValue: baseline.sleepQualityBaseline,
                            unit: "/5",
                            higherIsBetter: true,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Muscle Soreness",
                            icon: "figure.walk",
                            todayValue: assessment.subjectiveAssessment.map { Double($0.muscleSoreness) },
                            baselineValue: baseline.sorenessBaseline,
                            unit: "/5",
                            higherIsBetter: true,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )

                        Divider()

                        DimensionRow(
                            title: "Energy Level",
                            icon: "bolt.fill",
                            todayValue: assessment.subjectiveAssessment.map { Double($0.energyLevel) },
                            baselineValue: baseline.energyBaseline,
                            unit: "/5",
                            higherIsBetter: true,
                            formatString: "%.0f",
                            baselineDayCount: baseline.dayCount
                        )
                    }

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle(dateLabel)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Section Card Builder

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ThemedSectionHeader(title: title, icon: icon, color: color)
            content()
        }
        .cardStyle()
    }

    // MARK: - Computed

    private var tapFrequency: Double? {
        guard let tap = assessment.tapTestResult else { return nil }
        return (tap.round1Frequency + tap.round2Frequency) / 2.0
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(assessment.date) {
            return "Today"
        } else if calendar.isDateInYesterday(assessment.date) {
            return "Yesterday"
        } else {
            return assessment.date.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(
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
            allAssessments: []
        )
    }
}

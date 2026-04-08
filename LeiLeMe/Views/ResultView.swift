import SwiftUI

struct ResultView: View {
    let assessment: DailyAssessment
    let baseline: BaselineEngine.BaselineSnapshot

    @State private var showBaselineInfo = false
    @State private var appearAnimation = false

    private var isBaselineBuilding: Bool {
        baseline.dayCount > 0 && baseline.dayCount < 7
    }

    private var recoveryResult: RecoveryScoreEngine.Result {
        RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
    }

    var body: some View {
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.wellnessGreen)
                            .scaleEffect(appearAnimation ? 1.0 : 0.5)
                            .opacity(appearAnimation ? 1.0 : 0)

                        Text("Assessment Complete")
                            .font(.title2.bold())
                            .opacity(appearAnimation ? 1.0 : 0)
                    }
                    .padding(.top, AppSpacing.lg)

                    // Recovery recommendation card
                    RecoveryRecommendationCard(
                        result: recoveryResult,
                        baselineDayCount: baseline.dayCount
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .opacity(appearAnimation ? 1.0 : 0)
                    .offset(y: appearAnimation ? 0 : 20)

                    // Baseline progress banner during bootstrap period
                    if isBaselineBuilding {
                        BaselineProgressCard(dayCount: baseline.dayCount, showInfo: $showBaselineInfo)
                            .cardStyle()
                            .padding(.horizontal, AppSpacing.md)
                    }

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
                            todayValue: tapFrequencyToday,
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
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showBaselineInfo) {
            BaselineInfoSheet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appearAnimation = true
            }
        }
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

    private var tapFrequencyToday: Double? {
        guard let tap = assessment.tapTestResult else { return nil }
        return (tap.round1Frequency + tap.round2Frequency) / 2.0
    }
}

// MARK: - Baseline Progress Card

private struct BaselineProgressCard: View {
    let dayCount: Int
    @Binding var showInfo: Bool

    private var progress: Double {
        Double(dayCount) / 7.0
    }

    private var encouragingMessage: String {
        switch dayCount {
        case 1: return "Great start! Your personal baseline is forming."
        case 2: return "Nice consistency! Keep the daily check-ins going."
        case 3: return "Almost halfway there. Patterns are emerging!"
        case 4: return "Over the halfway mark. Your data is getting richer."
        case 5: return "Strong streak! Two more days to a full baseline."
        case 6: return "Tomorrow your baseline will be complete!"
        default: return "Your personal baseline is forming."
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.wellnessTeal, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: dayCount)
                Text("\(dayCount)/7")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.wellnessTeal)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(dayCount) of 7")
                    .font(.subheadline.weight(.semibold))
                Text(encouragingMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Baseline Info Sheet

private struct BaselineInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What is a Baseline?")
                        .font(.title2.bold())

                    Text("Your personal baseline is a 7-day rolling average of all your metrics \u{2014} HRV, resting heart rate, tap speed, reaction time, and subjective ratings.")
                        .font(.body)

                    Label {
                        Text("We need 7 days of data to establish reliable averages. Until then, you\u{2019}ll see your raw values without comparisons.")
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(Color.wellnessTeal)
                    }
                    .font(.body)

                    Label {
                        Text("Once established, your baseline updates daily. Each result is compared against your recent trend so you can spot changes.")
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color.wellnessTeal)
                    }
                    .font(.body)

                    Label {
                        Text("Consistency matters \u{2014} try to assess at roughly the same time each day for the most reliable comparisons.")
                    } icon: {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(Color.wellnessTeal)
                    }
                    .font(.body)
                }
                .padding()
            }
            .navigationTitle("About Baselines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
                dayCount: 3
            )
        )
    }
}

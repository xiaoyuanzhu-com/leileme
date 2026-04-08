import SwiftUI

struct ResultView: View {
    let assessment: DailyAssessment
    let baseline: BaselineEngine.BaselineSnapshot

    @State private var showBaselineInfo = false

    private var isBaselineBuilding: Bool {
        baseline.dayCount > 0 && baseline.dayCount < 7
    }

    var body: some View {
        List {
            // Baseline progress banner during bootstrap period
            if isBaselineBuilding {
                Section {
                    BaselineProgressCard(dayCount: baseline.dayCount, showInfo: $showBaselineInfo)
                }
            }

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
        .sheet(isPresented: $showBaselineInfo) {
            BaselineInfoSheet()
        }
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
        HStack(spacing: 16) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: dayCount)
                Text("\(dayCount)/7")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.accentColor)
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
        .padding(.vertical, 4)
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
                            .foregroundStyle(Color.accentColor)
                    }
                    .font(.body)

                    Label {
                        Text("Once established, your baseline updates daily. Each result is compared against your recent trend so you can spot changes.")
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color.accentColor)
                    }
                    .font(.body)

                    Label {
                        Text("Consistency matters \u{2014} try to assess at roughly the same time each day for the most reliable comparisons.")
                    } icon: {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(Color.accentColor)
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

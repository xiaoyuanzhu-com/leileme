import SwiftUI
import SwiftData

struct AssessmentTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]
    @State private var showAssessmentFlow = false

    private var todayAssessment: DailyAssessment? {
        let calendar = Calendar.current
        return assessments.first { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Hero icon
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Daily Assessment")
                    .font(.largeTitle.bold())

                Text("A ~90 second check-in covering\nhealth data, motor tests, and how you feel.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Start button
                Button {
                    showAssessmentFlow = true
                } label: {
                    Text(todayAssessment != nil ? "Redo Assessment" : "Start Assessment")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)

                // Today's summary or last assessed info
                if let today = todayAssessment {
                    todaySummary(today)
                        .padding(.horizontal, 24)
                } else if let latest = assessments.first {
                    lastAssessedLabel(latest)
                }

                Spacer()
            }
            .navigationTitle("Assessment")
            .fullScreenCover(isPresented: $showAssessmentFlow) {
                AssessmentFlowView()
            }
        }
    }

    // MARK: - Today Summary

    private func todaySummary(_ assessment: DailyAssessment) -> some View {
        VStack(spacing: 12) {
            Text("Today's Results")
                .font(.headline)

            HStack(spacing: 16) {
                if let tap = assessment.tapTestResult {
                    summaryItem(
                        icon: "hand.tap.fill",
                        label: "Tap",
                        value: String(format: "%.1f/s", (tap.round1Frequency + tap.round2Frequency) / 2.0)
                    )
                }

                if let rt = assessment.reactionTimeResult {
                    summaryItem(
                        icon: "bolt.circle.fill",
                        label: "Reaction",
                        value: "\(Int(rt.averageMs)) ms"
                    )
                }

                if let sub = assessment.subjectiveAssessment {
                    summaryItem(
                        icon: "face.smiling",
                        label: "Energy",
                        value: "\(sub.energyLevel)/5"
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Last Assessed

    private func lastAssessedLabel(_ assessment: DailyAssessment) -> some View {
        Text("Last assessed: \(assessment.date.formatted(date: .abbreviated, time: .omitted))")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    AssessmentTab()
        .environment(HealthKitService())
        .modelContainer(for: [
            DailyAssessment.self,
            HealthKitReading.self,
            TapTestResult.self,
            ReactionTimeResult.self,
            SubjectiveAssessment.self,
        ], inMemory: true)
}

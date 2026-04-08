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

    private var isFirstTime: Bool {
        assessments.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.assessmentBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        Spacer(minLength: 40)

                        // Hero icon with subtle glow
                        ZStack {
                            Circle()
                                .fill(Color.wellnessTeal.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Circle()
                                .fill(Color.wellnessTeal.opacity(0.05))
                                .frame(width: 160, height: 160)
                            Image(systemName: isFirstTime ? "figure.wave" : "heart.text.square")
                                .font(.system(size: 52))
                                .foregroundStyle(Color.wellnessTeal)
                        }

                        if isFirstTime {
                            firstTimeContent
                        } else {
                            returningContent
                        }

                        // Start button
                        Button {
                            showAssessmentFlow = true
                        } label: {
                            Text(buttonLabel)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, AppSpacing.xl)

                        // Today's summary or last assessed info
                        if let today = todayAssessment {
                            todaySummary(today)
                                .padding(.horizontal, AppSpacing.md)
                        } else if let latest = assessments.first {
                            lastAssessedLabel(latest)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationTitle("Assessment")
            .fullScreenCover(isPresented: $showAssessmentFlow) {
                AssessmentFlowView()
            }
        }
    }

    // MARK: - First Time Content

    private var firstTimeContent: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Welcome!")
                .font(.largeTitle.bold())

            Text("Start your first assessment to begin building your personal baseline. It takes about 90 seconds and covers health data, motor tests, and how you feel.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)

            Text("After 7 days of assessments, you\u{2019}ll unlock personalized comparisons against your own trends.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Returning Content

    private var returningContent: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Daily Check-in")
                .font(.largeTitle.bold())

            Text("A ~90 second check-in covering\nhealth data, motor tests, and how you feel.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
        }
    }

    private var buttonLabel: String {
        if isFirstTime {
            return "Begin First Assessment"
        } else if todayAssessment != nil {
            return "Redo Assessment"
        } else {
            return "Start Assessment"
        }
    }

    // MARK: - Today Summary

    private func todaySummary(_ assessment: DailyAssessment) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.wellnessGreen)
                Text("Today\u{2019}s Results")
                    .font(.headline)
            }

            HStack(spacing: AppSpacing.md) {
                if let tap = assessment.tapTestResult {
                    summaryItem(
                        icon: "hand.tap.fill",
                        label: "Tap",
                        value: String(format: "%.1f/s", (tap.round1Frequency + tap.round2Frequency) / 2.0),
                        color: .wellnessTeal
                    )
                }

                if let rt = assessment.reactionTimeResult {
                    summaryItem(
                        icon: "bolt.circle.fill",
                        label: "Reaction",
                        value: "\(Int(rt.averageMs)) ms",
                        color: .wellnessGreen
                    )
                }

                if let sub = assessment.subjectiveAssessment {
                    summaryItem(
                        icon: "face.smiling",
                        label: "Energy",
                        value: "\(sub.energyLevel)/5",
                        color: .wellnessAmber
                    )
                }
            }
        }
        .cardStyle()
    }

    private func summaryItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
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
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption)
            Text("Last assessed: \(assessment.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.footnote)
        }
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

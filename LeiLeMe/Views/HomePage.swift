import SwiftUI
import SwiftData

/// The main home page replacing the old TabView.
/// Shows recovery score card at top and a flat list of measure cards below.
struct HomePage: View {
    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]
    @Environment(\.modelContext) private var modelContext
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?

    private let baselineEngine = BaselineEngine()

    // MARK: - Computed properties

    private var todayAssessment: DailyAssessment? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return assessments.first { $0.date >= startOfToday }
    }

    private var baseline: BaselineEngine.BaselineSnapshot {
        baselineEngine.computeBaseline(from: assessments)
    }

    private var recoveryResult: RecoveryScoreEngine.Result {
        guard let today = todayAssessment else {
            if baseline.dayCount < 3 {
                return RecoveryScoreEngine.Result(
                    score: 0,
                    status: .neutral,
                    headline: baseline.dayCount > 0 ? "Building your profile" : "Welcome to LeiLeMe",
                    detail: baseline.dayCount > 0
                        ? "Day \(baseline.dayCount) of 7 \u{2014} keep checking in daily"
                        : "Complete your first assessment to get started",
                    availableDimensions: 0
                )
            }
            return RecoveryScoreEngine.Result(
                score: 0,
                status: .neutral,
                headline: "No data today",
                detail: "Tap a measure below to start today's check-in",
                availableDimensions: 0
            )
        }
        return RecoveryScoreEngine.evaluate(assessment: today, baseline: baseline)
    }

    /// Find the most recent non-nil value for a measure from past assessments (excluding today).
    private func lastValue(for measure: Measure) -> Double? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        for assessment in assessments {
            guard assessment.date < startOfToday else { continue }
            if let v = assessment.value(for: measure) {
                return v
            }
        }
        return nil
    }

    /// Whether there is any historical data for this measure (excluding today).
    private func hasHistory(for measure: Measure) -> Bool {
        lastValue(for: measure) != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // Recovery score card
                    RecoveryRecommendationCard(
                        result: recoveryResult,
                        baselineDayCount: baseline.dayCount
                    )

                    // Measure cards
                    ForEach(Measure.allCases) { measure in
                        MeasureCard(
                            measure: measure,
                            todayValue: todayAssessment?.value(for: measure),
                            baselineValue: baseline.value(for: measure),
                            lastValue: lastValue(for: measure),
                            hasHistory: hasHistory(for: measure)
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.surfaceBackground)
            .navigationTitle("\u{7D2F}\u{4E86}\u{4E48}")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsTab()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.wellnessTeal)
                    }
                }
            }
        }
    }
}

#Preview {
    HomePage()
        .environment(HealthKitService())
        .environment(AssessmentStore(modelContext: try! ModelContainer(for: DailyAssessment.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

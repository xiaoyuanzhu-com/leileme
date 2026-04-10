import SwiftUI
import SwiftData

/// The main home page replacing the old TabView.
/// Shows recovery score card at top and a flat list of measure cards below.
struct HomePage: View {
    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]
    @Environment(\.modelContext) private var modelContext
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?
    @Environment(HealthKitService.self) private var healthKitService: HealthKitService?
    @Environment(\.scenePhase) private var scenePhase

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
                    availableDimensions: 0,
                    totalDimensions: RecoveryScoreEngine.dimensionCount
                )
            }
            return RecoveryScoreEngine.Result(
                score: 0,
                status: .neutral,
                headline: "No data today",
                detail: "Tap a measure below to start today\u{2019}s check-in",
                availableDimensions: 0,
                totalDimensions: RecoveryScoreEngine.dimensionCount
            )
        }
        return RecoveryScoreEngine.evaluate(assessment: today, baseline: baseline)
    }


    /// Number of measures completed in today's assessment.
    private var todayCompletedCount: Int {
        guard let today = todayAssessment else { return 0 }
        return Measure.allCases.filter { today.value(for: $0) != nil }.count
    }

    /// Find the date of the most recent assessment containing a value for this measure (excluding today).
    private func lastDate(for measure: Measure) -> Date? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        for assessment in assessments {
            guard assessment.date < startOfToday else { continue }
            if assessment.value(for: measure) != nil {
                return assessment.date
            }
        }
        return nil
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
                        baselineDayCount: baseline.dayCount,
                        todayCompletedCount: todayCompletedCount
                    )

                    // Measure cards — each navigates to its detail page
                    ForEach(Measure.allCases) { measure in
                        NavigationLink(value: measure) {
                            MeasureCard(
                                measure: measure,
                                todayValue: todayAssessment?.value(for: measure),
                                baselineValue: baseline.value(for: measure),
                                lastValue: lastValue(for: measure),
                                lastDate: lastDate(for: measure),
                                hasHistory: hasHistory(for: measure),
                                healthKitAuthRequested: healthKitService?.hasRequestedAuthorization ?? false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.surfaceBackground)
            .navigationTitle("\u{7D2F}\u{4E86}\u{4E48}")
            .navigationDestination(for: Measure.self) { measure in
                MeasureDetailView(measure: measure)
            }
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
            .task(id: scenePhase) {
                await autoSyncHealthKit()
            }
        }
    }

    // MARK: - Auto-sync

    /// Automatically sync HealthKit data when the home page appears.
    /// Skips if data was already synced today or HealthKit is unavailable.
    private func autoSyncHealthKit() async {
        guard let healthKitService, let assessmentStore else { return }
        guard healthKitService.isAvailable else { return }

        // Skip if we already have HealthKit data today
        let hasHKData = assessmentStore.fetchTodayAssessment()?.healthKitData != nil
        guard !hasHKData else { return }

        do {
            try await healthKitService.requestAuthorization()
            let reading = try await healthKitService.fetchCurrentReading()
            assessmentStore.saveHealthKitReading(reading)
        } catch {
            // Silent failure for auto-sync — user can manually sync from detail page
        }
    }
}

#Preview {
    HomePage()
        .environment(HealthKitService())
        .environment(AssessmentStore(modelContext: try! ModelContainer(for: DailyAssessment.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

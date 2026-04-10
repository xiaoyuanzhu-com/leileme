import SwiftUI
import SwiftData
import Charts

/// Detail page for a single measure: About, Action, History.
struct MeasureDetailView: View {
    let measure: Measure

    @Environment(\.modelContext) private var modelContext
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?
    @Environment(HealthKitService.self) private var healthKitService: HealthKitService?

    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]

    @AppStorage private var aboutExpanded: Bool

    @State private var showingTest = false
    @State private var isSyncing = false
    @State private var syncError: String?

    init(measure: Measure) {
        self.measure = measure
        _aboutExpanded = AppStorage(wrappedValue: true, "aboutExpanded_\(measure.rawValue)")
    }

    // MARK: - Computed

    private var todayAssessment: DailyAssessment? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return assessments.first { $0.date >= startOfToday }
    }

    private var todayValue: Double? {
        todayAssessment?.value(for: measure)
    }

    private var todaySubjectiveInt: Int? {
        guard let sub = todayAssessment?.subjectiveAssessment else { return nil }
        switch measure {
        case .sleepQuality: return sub.sleepQuality > 0 ? sub.sleepQuality : nil
        case .muscleSoreness: return sub.muscleSoreness > 0 ? sub.muscleSoreness : nil
        case .energyLevel: return sub.energyLevel > 0 ? sub.energyLevel : nil
        default: return nil
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                aboutSection
                actionSection
                historySection
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(Color.surfaceBackground)
        .navigationTitle(measure.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - About Section

    @ViewBuilder
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    aboutExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(String(localized: "measureDetail.about \(measure.name)"), systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.wellnessTeal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(aboutExpanded ? 90 : 0))
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)

            if aboutExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(measure.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: measure.higherIsBetter ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.statusGood)
                        Text(measure.higherIsBetter
                             ? String(localized: "measure.higherIsBetter")
                             : String(localized: "measure.lowerIsBetter"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if measure == .tapFrequency {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(String(localized: "measure.tapFrequency.sharedNote"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } else if measure == .tapStability {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(String(localized: "measure.tapStability.sharedNote"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Action Section

    @ViewBuilder
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ThemedSectionHeader(title: String(localized: "measureDetail.action"), icon: "bolt.circle")
                .padding(.horizontal, AppSpacing.xs)

            switch measure.type {
            case .activeTest:
                activeTestAction
            case .healthKit:
                healthKitAction
            case .subjective:
                subjectiveAction
            }
        }
    }

    // MARK: Active Test Action

    @ViewBuilder
    private var activeTestAction: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                showingTest = true
            } label: {
                Text(todayValue != nil
                     ? String(localized: "measureDetail.redoTest")
                     : String(localized: "measureDetail.startTest"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .fullScreenCover(isPresented: $showingTest) {
                activeTestCover
            }
        }
    }


    @ViewBuilder
    private var activeTestCover: some View {
        switch measure {
        case .tapFrequency, .tapStability:
            TapTestView { result in
                assessmentStore?.saveTapTestResult(result)
                showingTest = false
            }
        case .reactionTime:
            ReactionTimeView { result in
                assessmentStore?.saveReactionTimeResult(result)
                showingTest = false
            }
        default:
            EmptyView()
        }
    }

    // MARK: HealthKit Action

    @ViewBuilder
    private var healthKitAction: some View {
        VStack(spacing: AppSpacing.md) {
            if let error = syncError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await syncHealthKit() }
            } label: {
                if isSyncing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(String(localized: "measureDetail.syncFromHealth"), systemImage: "heart.text.square")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSyncing)
        }
    }

    // MARK: Subjective Action

    @ViewBuilder
    private var subjectiveAction: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(subjectivePrompt)
                .font(.subheadline.weight(.medium))

            HStack(spacing: AppSpacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        assessmentStore?.saveSubjectiveRating(measure: measure, value: value)
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(value)")
                                .font(.title3.bold())
                            Text(subjectiveLabel(for: value))
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(todaySubjectiveInt == value ? Color.wellnessTeal : Color(.systemGray6))
                        )
                        .foregroundStyle(todaySubjectiveInt == value ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(todaySubjectiveInt == value ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: todaySubjectiveInt)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ThemedSectionHeader(title: String(localized: "measureDetail.history"), icon: "chart.xyaxis.line")
                .padding(.horizontal, AppSpacing.xs)

            let dataPoints = extractHistory()

            if dataPoints.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "measureDetail.firstMeasurement"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
                .cardStyle()
            } else {
                SingleMeasureTrendChart(
                    measure: measure,
                    dataPoints: dataPoints
                )
                .cardStyle()

                // Recent values list
                recentValuesList(dataPoints: dataPoints)
            }
        }
    }

    // MARK: - Helpers

    private func extractHistory() -> [MeasureDataPoint] {
        assessments.compactMap { assessment in
            guard let value = assessment.value(for: measure) else { return nil }
            return MeasureDataPoint(date: assessment.date, value: value)
        }
        .sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private func recentValuesList(dataPoints: [MeasureDataPoint]) -> some View {
        let recent = Array(dataPoints.suffix(15).reversed())
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(recent.enumerated()), id: \.offset) { index, point in
                HStack {
                    Text(point.date.formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: measure.formatString, point.value))
                            .font(.subheadline.weight(.medium).monospacedDigit())
                        Text(measure.unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)

                if index < recent.count - 1 {
                    Divider()
                        .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func syncHealthKit() async {
        guard let healthKitService, let assessmentStore else { return }
        isSyncing = true
        syncError = nil
        do {
            try await healthKitService.requestAuthorization()
            let reading = try await healthKitService.fetchCurrentReading()
            assessmentStore.saveHealthKitReading(reading)
        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
        }
        isSyncing = false
    }

    private var subjectivePrompt: String {
        switch measure {
        case .sleepQuality: return String(localized: "subjective.sleepQuality.prompt")
        case .muscleSoreness: return String(localized: "subjective.muscleSoreness.prompt")
        case .energyLevel: return String(localized: "subjective.energyLevel.prompt")
        default: return String(localized: "subjective.default.prompt")
        }
    }

    private func subjectiveLabel(for value: Int) -> String {
        let key: String
        switch measure {
        case .sleepQuality:
            key = "subjective.sleepQuality.\(value)"
        case .muscleSoreness:
            key = "subjective.muscleSoreness.\(value)"
        case .energyLevel:
            key = "subjective.energyLevel.\(value)"
        default:
            return "\(value)"
        }
        guard value >= 1, value <= 5 else { return "" }
        return String(localized: String.LocalizationValue(key))
    }
}

// MARK: - Data Point

struct MeasureDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeasureDetailView(measure: .hrvSDNN)
    }
    .environment(HealthKitService())
    .environment(AssessmentStore(modelContext: try! ModelContainer(for: DailyAssessment.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
    .modelContainer(for: DailyAssessment.self, inMemory: true)
}

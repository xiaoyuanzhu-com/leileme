import SwiftUI
import SwiftData

// MARK: - Flow Manager

@Observable
final class AssessmentFlowManager {

    enum Phase: Int, CaseIterable {
        case healthFetch
        case tapTest
        case reactionTime
        case subjective
        case results
    }

    var currentPhase: Phase = .healthFetch
    var healthKitReading: HealthKitReading?
    var tapTestResult: TapTestResult?
    var reactionTimeResult: ReactionTimeResult?
    var subjectiveAssessment: SubjectiveAssessment?
    var baseline: BaselineEngine.BaselineSnapshot?
    var dailyAssessment: DailyAssessment?

    var isComplete: Bool { currentPhase == .results }

    var phaseIndex: Int { currentPhase.rawValue }

    /// Total number of interactive phases (excluding results).
    static let interactivePhaseCount = Phase.allCases.count

    func advance() {
        guard let next = Phase(rawValue: currentPhase.rawValue + 1) else { return }
        currentPhase = next
    }
}

// MARK: - Flow View

struct AssessmentFlowView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var flowManager = AssessmentFlowManager()
    @State private var healthFetchError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !flowManager.isComplete {
                    progressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }

                phaseContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                if !flowManager.isComplete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(!flowManager.isComplete)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(AssessmentFlowManager.Phase.allCases, id: \.rawValue) { phase in
                Circle()
                    .fill(dotColor(for: phase))
                    .frame(width: 10, height: 10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: flowManager.phaseIndex)
    }

    private func dotColor(for phase: AssessmentFlowManager.Phase) -> Color {
        if phase.rawValue < flowManager.phaseIndex {
            return .accentColor
        } else if phase.rawValue == flowManager.phaseIndex {
            return .accentColor.opacity(0.6)
        } else {
            return Color(.systemGray4)
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch flowManager.currentPhase {
        case .healthFetch:
            healthFetchPhase
                .transition(.opacity)

        case .tapTest:
            TapTestView { result in
                flowManager.tapTestResult = result
                flowManager.advance()
            }
            .transition(.move(edge: .trailing))

        case .reactionTime:
            ReactionTimeView { result in
                flowManager.reactionTimeResult = result
                flowManager.advance()
            }
            .transition(.move(edge: .trailing))

        case .subjective:
            SubjectiveAssessmentView { assessment in
                flowManager.subjectiveAssessment = assessment
                completeAssessment()
            }
            .transition(.move(edge: .trailing))

        case .results:
            if let assessment = flowManager.dailyAssessment,
               let baseline = flowManager.baseline {
                ResultView(assessment: assessment, baseline: baseline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                    .transition(.move(edge: .trailing))
            }
        }
    }

    // MARK: - Health Fetch Phase

    private var healthFetchPhase: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Reading health data...")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let error = healthFetchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .task {
            await fetchHealthData()
        }
    }

    private func fetchHealthData() async {
        do {
            let reading = try await healthKitService.fetchCurrentReading()
            flowManager.healthKitReading = reading
        } catch {
            healthFetchError = "Could not read HealthKit data — continuing without it."
        }

        // Brief pause so the spinner is visible
        try? await Task.sleep(for: .milliseconds(600))
        flowManager.advance()
    }

    // MARK: - Completion

    private func completeAssessment() {
        let assessment = DailyAssessment(date: Date())
        assessment.healthKitData = flowManager.healthKitReading
        assessment.tapTestResult = flowManager.tapTestResult
        assessment.reactionTimeResult = flowManager.reactionTimeResult
        assessment.subjectiveAssessment = flowManager.subjectiveAssessment

        modelContext.insert(assessment)
        try? modelContext.save()

        // Compute baseline from history
        let baselineEngine = BaselineEngine()
        let descriptor = FetchDescriptor<DailyAssessment>()
        let allAssessments = (try? modelContext.fetch(descriptor)) ?? [assessment]
        let baseline = baselineEngine.computeBaseline(from: allAssessments)

        flowManager.dailyAssessment = assessment
        flowManager.baseline = baseline
        flowManager.advance()
    }
}

#Preview {
    AssessmentFlowView()
        .environment(HealthKitService())
        .modelContainer(for: [
            DailyAssessment.self,
            HealthKitReading.self,
            TapTestResult.self,
            ReactionTimeResult.self,
            SubjectiveAssessment.self,
        ], inMemory: true)
}

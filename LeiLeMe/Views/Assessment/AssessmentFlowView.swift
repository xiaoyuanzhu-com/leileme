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
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !flowManager.isComplete {
                        progressIndicator
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, 12)
                            .padding(.bottom, AppSpacing.sm)
                    }

                    phaseContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                if !flowManager.isComplete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .interactiveDismissDisabled(!flowManager.isComplete)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(AssessmentFlowManager.Phase.allCases.enumerated()), id: \.element.rawValue) { index, phase in
                if index > 0 {
                    // Connecting line
                    Rectangle()
                        .fill(phase.rawValue <= flowManager.phaseIndex
                              ? Color.wellnessTeal.opacity(0.5)
                              : Color(.systemGray5))
                        .frame(height: 2)
                }

                // Phase dot
                ZStack {
                    Circle()
                        .fill(dotFillColor(for: phase))
                        .frame(width: 14, height: 14)

                    if phase.rawValue < flowManager.phaseIndex {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    } else if phase.rawValue == flowManager.phaseIndex {
                        Circle()
                            .fill(.white)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: flowManager.phaseIndex)
    }

    private func dotFillColor(for phase: AssessmentFlowManager.Phase) -> Color {
        if phase.rawValue < flowManager.phaseIndex {
            return .wellnessTeal
        } else if phase.rawValue == flowManager.phaseIndex {
            return .wellnessTeal.opacity(0.7)
        } else {
            return Color(.systemGray5)
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch flowManager.currentPhase {
        case .healthFetch:
            healthFetchPhase
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .offset(x: -40))
                ))

        case .tapTest:
            TapTestView { result in
                flowManager.tapTestResult = result
                withAnimation(.easeInOut(duration: 0.35)) {
                    flowManager.advance()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .reactionTime:
            ReactionTimeView { result in
                flowManager.reactionTimeResult = result
                withAnimation(.easeInOut(duration: 0.35)) {
                    flowManager.advance()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .subjective:
            SubjectiveAssessmentView { assessment in
                flowManager.subjectiveAssessment = assessment
                completeAssessment()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .results:
            if let assessment = flowManager.dailyAssessment,
               let baseline = flowManager.baseline {
                ResultView(assessment: assessment, baseline: baseline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }

    // MARK: - Health Fetch Phase

    private var healthFetchPhase: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wellnessTeal.opacity(0.08))
                    .frame(width: 120, height: 120)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.wellnessTeal)
            }

            Text("Reading health data...")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            if let error = healthFetchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
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
            healthFetchError = "Could not read HealthKit data \u{2014} continuing without it."
        }

        // Brief pause so the spinner is visible
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.easeInOut(duration: 0.35)) {
            flowManager.advance()
        }
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
        withAnimation(.easeInOut(duration: 0.35)) {
            flowManager.advance()
        }
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

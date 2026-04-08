import SwiftUI
import SwiftData

struct AssessmentTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showTapTest = false
    @State private var showingReactionTime = false
    @State private var lastReactionResult: ReactionTimeResult?
    @State private var showingSubjectiveAssessment = false
    @State private var lastSubjectiveAssessment: SubjectiveAssessment?

    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    Button {
                        showTapTest = true
                    } label: {
                        Label("Tap Test", systemImage: "hand.tap.fill")
                    }

                    NavigationLink {
                        ReactionTimeView { result in
                            modelContext.insert(result)
                            lastReactionResult = result
                            showingReactionTime = false
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reaction Time")
                                    .font(.body)
                                Text("5-trial psychomotor vigilance task")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section("Subjective") {
                    Button {
                        showingSubjectiveAssessment = true
                    } label: {
                        Label(lastSubjectiveAssessment == nil ? "Start Check-in" : "Redo Check-in",
                              systemImage: "heart.text.clipboard")
                    }
                }

                if let result = lastReactionResult {
                    Section("Last Reaction Time Result") {
                        LabeledContent("Average", value: "\(Int(result.averageMs)) ms")
                        LabeledContent("Fastest", value: "\(Int(result.fastestMs)) ms")
                        LabeledContent("Consistency (SD)", value: "\(Int(result.standardDeviationMs)) ms")
                    }
                }

                if let assessment = lastSubjectiveAssessment {
                    Section("Last Check-in") {
                        LabeledContent("Sleep Quality", value: "\(assessment.sleepQuality)/5")
                        LabeledContent("Muscle Soreness", value: "\(assessment.muscleSoreness)/5")
                        LabeledContent("Energy Level", value: "\(assessment.energyLevel)/5")
                    }
                }
            }
            .navigationTitle("Assessment")
            .fullScreenCover(isPresented: $showTapTest) {
                TapTestView { result in
                    modelContext.insert(result)
                    showTapTest = false
                }
            }
            .navigationDestination(isPresented: $showingSubjectiveAssessment) {
                SubjectiveAssessmentView { assessment in
                    lastSubjectiveAssessment = assessment
                    showingSubjectiveAssessment = false
                }
            }
        }
    }
}

#Preview {
    AssessmentTab()
        .modelContainer(for: [TapTestResult.self, ReactionTimeResult.self], inMemory: true)
}

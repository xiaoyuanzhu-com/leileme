import SwiftUI
import SwiftData

struct AssessmentTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showTapTest = false
    @State private var showingReactionTime = false
    @State private var lastReactionResult: ReactionTimeResult?

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

                if let result = lastReactionResult {
                    Section("Last Reaction Time Result") {
                        LabeledContent("Average", value: "\(Int(result.averageMs)) ms")
                        LabeledContent("Fastest", value: "\(Int(result.fastestMs)) ms")
                        LabeledContent("Consistency (SD)", value: "\(Int(result.standardDeviationMs)) ms")
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
        }
    }
}

#Preview {
    AssessmentTab()
        .modelContainer(for: [TapTestResult.self, ReactionTimeResult.self], inMemory: true)
}

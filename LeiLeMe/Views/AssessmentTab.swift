import SwiftUI
import SwiftData

struct AssessmentTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingReactionTime = false
    @State private var lastResult: ReactionTimeResult?

    var body: some View {
        NavigationStack {
            List {
                Section("Cognitive Tests") {
                    NavigationLink {
                        ReactionTimeView { result in
                            modelContext.insert(result)
                            lastResult = result
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

                if let result = lastResult {
                    Section("Last Result") {
                        LabeledContent("Average", value: "\(Int(result.averageMs)) ms")
                        LabeledContent("Fastest", value: "\(Int(result.fastestMs)) ms")
                        LabeledContent("Consistency (SD)", value: "\(Int(result.standardDeviationMs)) ms")
                    }
                }
            }
            .navigationTitle("Assessment")
        }
    }
}

#Preview {
    AssessmentTab()
        .modelContainer(for: ReactionTimeResult.self, inMemory: true)
}

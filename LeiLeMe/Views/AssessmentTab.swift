import SwiftUI

struct AssessmentTab: View {
    @State private var showingSubjectiveAssessment = false
    @State private var lastAssessment: SubjectiveAssessment?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let assessment = lastAssessment {
                    VStack(spacing: 8) {
                        Text("Today's Check-in")
                            .font(.headline)
                        HStack(spacing: 16) {
                            AssessmentBadge(label: "Sleep", value: assessment.sleepQuality)
                            AssessmentBadge(label: "Soreness", value: assessment.muscleSoreness)
                            AssessmentBadge(label: "Energy", value: assessment.energyLevel)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingSubjectiveAssessment = true
                } label: {
                    Label(lastAssessment == nil ? "Start Check-in" : "Redo Check-in",
                          systemImage: "heart.text.clipboard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Assessment")
            .navigationDestination(isPresented: $showingSubjectiveAssessment) {
                SubjectiveAssessmentView { assessment in
                    lastAssessment = assessment
                    showingSubjectiveAssessment = false
                }
            }
        }
    }
}

private struct AssessmentBadge: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AssessmentTab()
}

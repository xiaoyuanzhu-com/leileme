import SwiftUI

struct SubjectiveAssessmentView: View {
    var onComplete: (SubjectiveAssessment) -> Void

    @State private var sleepQuality: Int? = nil
    @State private var muscleSoreness: Int? = nil
    @State private var energyLevel: Int? = nil

    private var allSelected: Bool {
        sleepQuality != nil && muscleSoreness != nil && energyLevel != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                RatingQuestion(
                    prompt: "How well did you sleep?",
                    labels: ["Terrible", "Poor", "Okay", "Good", "Great"],
                    selection: $sleepQuality
                )

                RatingQuestion(
                    prompt: "How sore are your muscles?",
                    labels: ["Very sore", "Sore", "Moderate", "Mild", "Not at all"],
                    selection: $muscleSoreness
                )

                RatingQuestion(
                    prompt: "How's your energy?",
                    labels: ["Exhausted", "Low", "Moderate", "Good", "Energized"],
                    selection: $energyLevel
                )

                Button {
                    guard let sleep = sleepQuality,
                          let soreness = muscleSoreness,
                          let energy = energyLevel else { return }
                    let assessment = SubjectiveAssessment(
                        sleepQuality: sleep,
                        muscleSoreness: soreness,
                        energyLevel: energy
                    )
                    onComplete(assessment)
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!allSelected)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .navigationTitle("How are you feeling?")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Rating Question

private struct RatingQuestion: View {
    let prompt: String
    let labels: [String]
    @Binding var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    RatingButton(
                        value: value,
                        label: labels[value - 1],
                        isSelected: selection == value
                    ) {
                        selection = value
                    }
                }
            }
        }
    }
}

// MARK: - Rating Button

private struct RatingButton: View {
    let value: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.title3.bold())
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(value), \(label)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubjectiveAssessmentView { assessment in
            print("Sleep: \(assessment.sleepQuality), Soreness: \(assessment.muscleSoreness), Energy: \(assessment.energyLevel)")
        }
    }
}

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
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.wellnessTeal)
                        Text("How are you feeling?")
                            .font(.title2.bold())
                    }
                    .padding(.top, AppSpacing.lg)

                    RatingQuestion(
                        prompt: "How well did you sleep?",
                        icon: "bed.double.fill",
                        labels: ["Terrible", "Poor", "Okay", "Good", "Great"],
                        selection: $sleepQuality
                    )

                    RatingQuestion(
                        prompt: "How sore are your muscles?",
                        icon: "figure.walk",
                        labels: ["None", "Mild", "Moderate", "Sore", "Very sore"],
                        selection: $muscleSoreness
                    )

                    RatingQuestion(
                        prompt: "How's your energy?",
                        icon: "bolt.fill",
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
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!allSelected)
                    .opacity(allSelected ? 1.0 : 0.5)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rating Question

private struct RatingQuestion: View {
    let prompt: String
    let icon: String
    let labels: [String]
    @Binding var selection: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.wellnessTeal)
                    .font(.subheadline)
                Text(prompt)
                    .font(.headline)
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    RatingButton(
                        value: value,
                        label: labels[value - 1],
                        isSelected: selection == value
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selection = value
                        }
                    }
                }
            }
        }
        .cardStyle()
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.wellnessTeal : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isSelected)
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

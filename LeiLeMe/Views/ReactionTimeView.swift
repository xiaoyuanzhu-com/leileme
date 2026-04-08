import SwiftUI

/// Full-screen 5-trial Psychomotor Vigilance Task.
struct ReactionTimeView: View {
    @State private var engine = ReactionTimeEngine()
    var onComplete: ((ReactionTimeResult) -> Void)?

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    engine.onTap()
                }

            VStack(spacing: AppSpacing.lg) {
                switch engine.state {
                case .ready:
                    readyContent

                case .waiting(let trial):
                    waitingContent(trial: trial)

                case .stimulus(let trial):
                    stimulusContent(trial: trial)

                case .tooEarly(let trial):
                    tooEarlyContent(trial: trial)

                case .feedback(let trial, let ms):
                    feedbackContent(trial: trial, ms: ms)

                case .complete(let result):
                    completeContent(result: result)
                }
            }
            .padding()
            .allowsHitTesting(false) // let taps pass through to background
        }
        .navigationBarBackButtonHidden(engine.state != .ready)
        .statusBarHidden(engine.state != .ready && engine.state != .complete(engine.computeResult()))
    }

    // MARK: - Background Color

    private var backgroundColor: Color {
        switch engine.state {
        case .ready:
            return Color.surfaceBackground
        case .waiting:
            return Color(.systemGray5)
        case .stimulus:
            return Color.wellnessGreen
        case .tooEarly:
            return Color.wellnessRed.opacity(0.3)
        case .feedback:
            return Color.surfaceBackground
        case .complete:
            return Color.surfaceBackground
        }
    }

    // MARK: - State Views

    private var readyContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wellnessGreen.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color.wellnessGreen.opacity(0.05))
                    .frame(width: 180, height: 180)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.wellnessGreen)
            }

            Text("Reaction Time")
                .font(.largeTitle.bold())

            Text("When the screen turns **green**, tap as fast as you can.\n\n5 rounds.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()

            Button {
                engine.start()
            } label: {
                Text("Start")
            }
            .buttonStyle(PrimaryButtonStyle(color: .wellnessGreen))
            .padding(.horizontal, AppSpacing.xxl)
            .allowsHitTesting(true)

            Spacer()
        }
    }

    private func waitingContent(trial: Int) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Text("Trial \(trial) of \(engine.totalTrials)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Wait for green...")
                .font(.title.bold())
                .foregroundStyle(.primary)

            // Subtle waiting indicator
            ProgressView()
                .tint(.secondary)

            Spacer()
        }
    }

    private func stimulusContent(trial: Int) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Text("TAP NOW!")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)

            // Pulsing circle
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 100, height: 100)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }

    private func tooEarlyContent(trial: Int) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.wellnessRed)

            Text("Too early!")
                .font(.title.bold())
                .foregroundStyle(Color.wellnessRed)

            Text("Wait for the green screen.")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Retrying trial \(trial)...")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func feedbackContent(trial: Int, ms: Double) -> some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Text("Trial \(trial) of \(engine.totalTrials)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("\(Int(ms)) ms")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(reactionColor(ms: ms))

            Text(reactionQuality(ms: ms))
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text("Tap to continue")
                .font(.callout)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    private func completeContent(result: ReactionTimeResult) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Spacer(minLength: 20)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.wellnessGreen)

                Text("Results")
                    .font(.largeTitle.bold())

                // Summary card
                VStack(spacing: 12) {
                    resultRow(label: "Average", value: "\(Int(result.averageMs)) ms")
                    resultRow(label: "Fastest", value: "\(Int(result.fastestMs)) ms")
                    resultRow(label: "Slowest", value: "\(Int(result.slowestMs)) ms")
                    resultRow(label: "Std Dev", value: "\(Int(result.standardDeviationMs)) ms")
                }
                .cardStyle()
                .padding(.horizontal, AppSpacing.md)

                // Individual trials card
                VStack(spacing: AppSpacing.sm) {
                    Text("Individual Trials")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ForEach(Array(result.reactionTimesMs.enumerated()), id: \.offset) { index, time in
                            VStack(spacing: 4) {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(time))")
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(reactionColor(ms: time))
                                Text("ms")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: 20)

                Button {
                    onComplete?(result)
                } label: {
                    Text("Done")
                }
                .buttonStyle(PrimaryButtonStyle(color: .wellnessGreen))
                .padding(.horizontal, AppSpacing.xxl)
                .allowsHitTesting(true)

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Helpers

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.bold().monospacedDigit())
        }
    }

    private func reactionColor(ms: Double) -> Color {
        switch ms {
        case ..<200: return .wellnessGreen
        case ..<300: return .wellnessTeal
        case ..<400: return .wellnessAmber
        default: return .wellnessRed
        }
    }

    private func reactionQuality(ms: Double) -> String {
        switch ms {
        case ..<200: return "Excellent!"
        case ..<300: return "Good"
        case ..<400: return "Average"
        default: return "Slow"
        }
    }
}

#Preview {
    NavigationStack {
        ReactionTimeView()
    }
}

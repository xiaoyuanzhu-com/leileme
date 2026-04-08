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

            VStack(spacing: 24) {
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
            return Color(.systemBackground)
        case .waiting:
            return Color(.systemGray5)
        case .stimulus:
            return .green
        case .tooEarly:
            return Color(.systemRed).opacity(0.3)
        case .feedback:
            return Color(.systemBackground)
        case .complete:
            return Color(.systemBackground)
        }
    }

    // MARK: - State Views

    private var readyContent: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Reaction Time Test")
                .font(.largeTitle.bold())

            Text("When the screen turns **green**, tap as fast as you can.\n\n5 rounds.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                engine.start()
            } label: {
                Text("Start")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 48)
            .allowsHitTesting(true)

            Spacer()
        }
    }

    private func waitingContent(trial: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Trial \(trial) of \(engine.totalTrials)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Wait for green...")
                .font(.title.bold())
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    private func stimulusContent(trial: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Text("TAP NOW!")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)

            Circle()
                .fill(.white.opacity(0.4))
                .frame(width: 120, height: 120)

            Spacer()
        }
    }

    private func tooEarlyContent(trial: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Too early!")
                .font(.title.bold())
                .foregroundStyle(.red)

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
        VStack(spacing: 16) {
            Spacer()

            Text("Trial \(trial) of \(engine.totalTrials)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("\(Int(ms)) ms")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.green)

            Text(reactionQuality(ms: ms))
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Tap to continue")
                .font(.callout)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    private func completeContent(result: ReactionTimeResult) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Results")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                resultRow(label: "Average", value: "\(Int(result.averageMs)) ms")
                resultRow(label: "Fastest", value: "\(Int(result.fastestMs)) ms")
                resultRow(label: "Slowest", value: "\(Int(result.slowestMs)) ms")
                resultRow(label: "Std Dev", value: "\(Int(result.standardDeviationMs)) ms")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Individual trials
            VStack(spacing: 8) {
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
                            Text("ms")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                onComplete?(result)
            } label: {
                Text("Done")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 48)
            .allowsHitTesting(true)

            Spacer()
        }
        .padding(.horizontal)
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

import SwiftUI

struct TapTestView: View {
    @State private var engine = TapTestEngine()
    @State private var showTapFlash = false
    var onComplete: ((TapTestResult) -> Void)?

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            switch engine.state {
            case .ready:
                readyView
            case .round1(let remaining):
                roundView(round: 1, timeRemaining: remaining)
            case .rest(let remaining):
                restView(timeRemaining: remaining)
            case .round2(let remaining):
                roundView(round: 2, timeRemaining: remaining)
            case .complete(let result):
                completeView(result: result)
            }
        }
        .statusBarHidden(engine.isActive)
    }

    // MARK: - Background

    private var backgroundColor: Color {
        if showTapFlash {
            return Color.blue.opacity(0.3)
        }
        switch engine.state {
        case .ready, .complete:
            return Color(.systemBackground)
        case .round1, .round2:
            return Color(.systemBackground)
        case .rest:
            return Color(.secondarySystemBackground)
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Tap Test")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                Text("Tap the screen as fast as you can\nfor 10 seconds.")
                    .multilineTextAlignment(.center)
                    .font(.title3)

                Text("Two rounds with a short rest between.")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }

            Spacer()

            Button(action: { engine.start() }) {
                Text("Start")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Round

    private func roundView(round: Int, timeRemaining: Double) -> some View {
        ZStack {
            // Full-screen tap target
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap()
                }

            VStack(spacing: 24) {
                Text("Round \(round)")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.1f", timeRemaining))
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("\(engine.tapCount)")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)

                Text("taps")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Rest

    private func restView(timeRemaining: Double) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Round 1 done!")
                .font(.title.bold())

            Text("Get ready for round 2...")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(String(format: "%.0f", ceil(timeRemaining)))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()

            Spacer()
        }
    }

    // MARK: - Complete

    private func completeView(result: TapTestResult) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Test Complete")
                .font(.largeTitle.bold())

            VStack(spacing: 16) {
                resultRow(label: "Round 1", value: "\(result.round1Taps) taps", detail: String(format: "%.1f/sec", result.round1Frequency))
                resultRow(label: "Round 2", value: "\(result.round2Taps) taps", detail: String(format: "%.1f/sec", result.round2Frequency))

                Divider()
                    .padding(.horizontal, 40)

                resultRow(label: "Rhythm Stability", value: String(format: "CV %.3f", result.rhythmStability), detail: stabilityLabel(result.rhythmStability))
                resultRow(label: "Fatigue Decay", value: String(format: "%.1f%%", result.fatigueDecay * 100), detail: fatigueLabel(result.fatigueDecay))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: {
                onComplete?(result)
            }) {
                Text("Done")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            Button("Try Again") {
                engine.reset()
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func resultRow(label: String, value: String, detail: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing) {
                Text(value)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stabilityLabel(_ cv: Double) -> String {
        if cv < 0.1 { return "Very stable" }
        if cv < 0.2 { return "Stable" }
        if cv < 0.3 { return "Moderate" }
        return "Variable"
    }

    private func fatigueLabel(_ decay: Double) -> String {
        if decay >= 0.95 { return "No fatigue" }
        if decay >= 0.85 { return "Mild fatigue" }
        if decay >= 0.75 { return "Moderate fatigue" }
        return "Significant fatigue"
    }

    private func handleTap() {
        engine.recordTap()
        triggerHaptic()
        flashFeedback()
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func flashFeedback() {
        showTapFlash = true
        withAnimation(.easeOut(duration: 0.1)) {
            showTapFlash = false
        }
    }
}

#Preview {
    TapTestView()
}

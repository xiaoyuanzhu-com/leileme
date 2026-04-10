import SwiftUI

struct TapTestView: View {
    @State private var engine = TapTestEngine()
    @State private var showTapFlash = false
    @State private var tapScale: CGFloat = 1.0
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
            return Color.wellnessTeal.opacity(0.15)
        }
        switch engine.state {
        case .ready, .complete:
            return Color.surfaceBackground
        case .round1, .round2:
            return Color.surfaceBackground
        case .rest:
            return Color(.secondarySystemBackground)
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wellnessTeal.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.wellnessTeal)
            }

            Text(String(localized: "tapTest.title"))
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                Text(String(localized: "tapTest.instruction"))
                    .multilineTextAlignment(.center)
                    .font(.title3)

                Text(String(localized: "tapTest.twoRounds"))
                    .foregroundStyle(.secondary)
                    .font(.body)
            }

            Spacer()

            Button(action: { engine.start() }) {
                Text(String(localized: "tapTest.start"))
            }
            .buttonStyle(PrimaryButtonStyle())
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

            VStack(spacing: AppSpacing.lg) {
                Text(String(localized: "tapTest.round \(round)"))
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)

                // Timer ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: timeRemaining / 10.0)
                        .stroke(Color.wellnessTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: timeRemaining)

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", timeRemaining))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(String(localized: "tapTest.seconds"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Tap counter with pulse feedback
                VStack(spacing: 4) {
                    Text("\(engine.tapCount)")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.wellnessTeal)
                        .scaleEffect(tapScale)

                    Text(String(localized: "tapTest.taps"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Rest

    private func restView(timeRemaining: Double) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.wellnessGreen)

            Text(String(localized: "tapTest.round1Done"))
                .font(.title.bold())

            Text(String(localized: "tapTest.getReady"))
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(String(format: "%.0f", ceil(timeRemaining)))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.wellnessTeal)

            Spacer()
        }
    }

    // MARK: - Complete

    private func completeView(result: TapTestResult) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Spacer(minLength: 20)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.wellnessGreen)

                Text(String(localized: "tapTest.complete"))
                    .font(.largeTitle.bold())

                // Results card
                VStack(spacing: AppSpacing.md) {
                    resultRow(label: String(localized: "tapTest.round1Label"), value: String(localized: "tapTest.tapsCount \(result.round1Taps)"), detail: String(format: "%.1f/sec", result.round1Frequency))
                    resultRow(label: String(localized: "tapTest.round2Label"), value: String(localized: "tapTest.tapsCount \(result.round2Taps)"), detail: String(format: "%.1f/sec", result.round2Frequency))

                    Divider()

                    resultRow(label: String(localized: "tapTest.rhythmStability"), value: String(format: "CV %.3f", result.rhythmStability), detail: stabilityLabel(result.rhythmStability))
                    resultRow(label: String(localized: "tapTest.fatigueDecay"), value: String(format: "%.1f%%", result.fatigueDecay * 100), detail: fatigueLabel(result.fatigueDecay))
                }
                .cardStyle()
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: 20)

                Button(action: {
                    onComplete?(result)
                }) {
                    Text(String(localized: "tapTest.done"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)

                Button(String(localized: "tapTest.tryAgain")) {
                    engine.reset()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Helpers

    private func resultRow(label: String, value: String, detail: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stabilityLabel(_ cv: Double) -> String {
        if cv < 0.1 { return String(localized: "tapTest.stability.veryStable") }
        if cv < 0.2 { return String(localized: "tapTest.stability.stable") }
        if cv < 0.3 { return String(localized: "tapTest.stability.moderate") }
        return String(localized: "tapTest.stability.variable")
    }

    private func fatigueLabel(_ decay: Double) -> String {
        if decay >= 0.95 { return String(localized: "tapTest.fatigue.none") }
        if decay >= 0.85 { return String(localized: "tapTest.fatigue.mild") }
        if decay >= 0.75 { return String(localized: "tapTest.fatigue.moderate") }
        return String(localized: "tapTest.fatigue.significant")
    }

    private func handleTap() {
        engine.recordTap()
        triggerHaptic()
        flashFeedback()
        // Pulse the tap counter
        withAnimation(.easeOut(duration: 0.08)) {
            tapScale = 1.15
        }
        withAnimation(.easeIn(duration: 0.08).delay(0.08)) {
            tapScale = 1.0
        }
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

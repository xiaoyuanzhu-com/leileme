import Foundation
import UIKit

/// Drives a 5-trial Psychomotor Vigilance Task (PVT).
@Observable
class ReactionTimeEngine {

    enum State: Equatable {
        case ready
        case waiting(trial: Int)
        case stimulus(trial: Int)
        case tooEarly(trial: Int)
        case feedback(trial: Int, ms: Double)
        case complete(ReactionTimeResult)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.ready, .ready):
                return true
            case let (.waiting(a), .waiting(b)):
                return a == b
            case let (.stimulus(a), .stimulus(b)):
                return a == b
            case let (.tooEarly(a), .tooEarly(b)):
                return a == b
            case let (.feedback(a1, a2), .feedback(b1, b2)):
                return a1 == b1 && a2 == b2
            case (.complete, .complete):
                return true
            default:
                return false
            }
        }
    }

    var state: State = .ready
    let totalTrials: Int = 5

    private var reactionTimes: [Double] = []
    private var stimulusTime: Date?
    private var waitTask: Task<Void, Never>?

    var currentTrialNumber: Int {
        switch state {
        case .ready:
            return 0
        case .waiting(let trial), .stimulus(let trial),
             .tooEarly(let trial), .feedback(let trial, _):
            return trial
        case .complete:
            return totalTrials
        }
    }

    // MARK: - Actions

    func start() {
        reactionTimes = []
        stimulusTime = nil
        beginWaiting(trial: 1)
    }

    func onTap() {
        switch state {
        case .waiting:
            // Tapped before stimulus — too early
            waitTask?.cancel()
            waitTask = nil
            state = .tooEarly(trial: currentTrialNumber)
            triggerHaptic(style: .heavy)

            // Auto-retry after a short delay
            let trial = currentTrialNumber
            waitTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                beginWaiting(trial: trial)
            }

        case .stimulus(let trial):
            // Valid tap — record reaction time
            guard let onset = stimulusTime else { return }
            let elapsed = Date().timeIntervalSince(onset) * 1000.0 // ms
            reactionTimes.append(elapsed)
            state = .feedback(trial: trial, ms: elapsed)
            triggerHaptic(style: .light)

        case .feedback:
            nextTrial()

        default:
            break
        }
    }

    func nextTrial() {
        let next = currentTrialNumber + 1
        if next > totalTrials {
            state = .complete(computeResult())
        } else {
            beginWaiting(trial: next)
        }
    }

    func reset() {
        waitTask?.cancel()
        waitTask = nil
        reactionTimes = []
        stimulusTime = nil
        state = .ready
    }

    // MARK: - Internal

    private func beginWaiting(trial: Int) {
        state = .waiting(trial: trial)
        stimulusTime = nil

        let delay = Double.random(in: 2.0...5.0)
        waitTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            showStimulus(trial: trial)
        }
    }

    private func showStimulus(trial: Int) {
        stimulusTime = Date()
        state = .stimulus(trial: trial)
        triggerHaptic(style: .medium)
    }

    func computeResult() -> ReactionTimeResult {
        let times = reactionTimes
        guard !times.isEmpty else {
            return ReactionTimeResult(
                reactionTimesMs: [],
                averageMs: 0,
                standardDeviationMs: 0,
                fastestMs: 0,
                slowestMs: 0
            )
        }
        let avg = times.reduce(0, +) / Double(times.count)
        let fastest = times.min() ?? 0
        let slowest = times.max() ?? 0
        let variance = times.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(times.count)
        let stddev = variance.squareRoot()

        return ReactionTimeResult(
            reactionTimesMs: times,
            averageMs: avg,
            standardDeviationMs: stddev,
            fastestMs: fastest,
            slowestMs: slowest
        )
    }

    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

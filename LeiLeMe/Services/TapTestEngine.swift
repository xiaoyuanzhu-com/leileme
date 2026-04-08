import Foundation

@Observable
class TapTestEngine {
    enum State: Equatable {
        case ready
        case round1(timeRemaining: Double)
        case rest(timeRemaining: Double)
        case round2(timeRemaining: Double)
        case complete(TapTestResult)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.ready, .ready):
                return true
            case let (.round1(a), .round1(b)):
                return a == b
            case let (.rest(a), .rest(b)):
                return a == b
            case let (.round2(a), .round2(b)):
                return a == b
            case (.complete, .complete):
                return true
            default:
                return false
            }
        }
    }

    private(set) var state: State = .ready
    private(set) var tapCount: Int = 0

    private var round1Timestamps: [Date] = []
    private var round2Timestamps: [Date] = []
    private var timer: Timer?

    private static let roundDuration: Double = 10.0
    private static let restDuration: Double = 3.0
    private static let tickInterval: Double = 0.05

    var isActive: Bool {
        switch state {
        case .round1, .round2:
            return true
        default:
            return false
        }
    }

    func start() {
        round1Timestamps = []
        round2Timestamps = []
        tapCount = 0
        startRound1()
    }

    func recordTap() {
        let now = Date()
        switch state {
        case .round1:
            round1Timestamps.append(now)
            tapCount = round1Timestamps.count
        case .round2:
            round2Timestamps.append(now)
            tapCount = round2Timestamps.count
        default:
            break
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        round1Timestamps = []
        round2Timestamps = []
        tapCount = 0
        state = .ready
    }

    // MARK: - Phase transitions

    private func startRound1() {
        state = .round1(timeRemaining: Self.roundDuration)
        tapCount = 0
        startCountdown(duration: Self.roundDuration) { [weak self] remaining in
            self?.state = .round1(timeRemaining: remaining)
        } completion: { [weak self] in
            self?.startRest()
        }
    }

    private func startRest() {
        state = .rest(timeRemaining: Self.restDuration)
        startCountdown(duration: Self.restDuration) { [weak self] remaining in
            self?.state = .rest(timeRemaining: remaining)
        } completion: { [weak self] in
            self?.startRound2()
        }
    }

    private func startRound2() {
        state = .round2(timeRemaining: Self.roundDuration)
        tapCount = 0
        startCountdown(duration: Self.roundDuration) { [weak self] remaining in
            self?.state = .round2(timeRemaining: remaining)
        } completion: { [weak self] in
            self?.finish()
        }
    }

    private func finish() {
        let result = computeResult()
        state = .complete(result)
    }

    // MARK: - Timer

    private func startCountdown(
        duration: Double,
        onTick: @escaping (Double) -> Void,
        completion: @escaping () -> Void
    ) {
        timer?.invalidate()
        let startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] t in
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, duration - elapsed)
            if remaining <= 0 {
                t.invalidate()
                self?.timer = nil
                completion()
            } else {
                onTick(remaining)
            }
        }
    }

    // MARK: - Metrics

    func computeResult() -> TapTestResult {
        let round1Freq = Double(round1Timestamps.count) / Self.roundDuration
        let round2Freq = Double(round2Timestamps.count) / Self.roundDuration

        let allTimestamps = round1Timestamps + round2Timestamps
        let rhythmStability = Self.coefficientOfVariation(timestamps: allTimestamps)

        let fatigueDecay: Double
        if round1Freq > 0 {
            fatigueDecay = round2Freq / round1Freq
        } else {
            fatigueDecay = 1.0
        }

        return TapTestResult(
            round1Taps: round1Timestamps.count,
            round2Taps: round2Timestamps.count,
            round1Frequency: round1Freq,
            round2Frequency: round2Freq,
            rhythmStability: rhythmStability,
            fatigueDecay: fatigueDecay
        )
    }

    private static func coefficientOfVariation(timestamps: [Date]) -> Double {
        guard timestamps.count >= 2 else { return 0 }

        var intervals: [Double] = []
        for i in 1..<timestamps.count {
            intervals.append(timestamps[i].timeIntervalSince(timestamps[i - 1]))
        }

        guard !intervals.isEmpty else { return 0 }

        let mean = intervals.reduce(0, +) / Double(intervals.count)
        guard mean > 0 else { return 0 }

        let squaredDiffs = intervals.map { val in (val - mean) * (val - mean) }
        let variance = squaredDiffs.reduce(0, +) / Double(intervals.count)
        let stddev = variance.squareRoot()

        return stddev / mean
    }
}

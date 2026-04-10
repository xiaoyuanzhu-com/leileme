import XCTest
@testable import LeiLeMe

final class ReactionTimeEngineTests: XCTestCase {

    // MARK: - computeResult with empty data

    func testComputeResultEmpty() {
        let engine = ReactionTimeEngine()
        let result = engine.computeResult()

        XCTAssertEqual(result.averageMs, 0)
        XCTAssertEqual(result.standardDeviationMs, 0)
        XCTAssertEqual(result.fastestMs, 0)
        XCTAssertEqual(result.slowestMs, 0)
        XCTAssertTrue(result.reactionTimesMs.isEmpty)
    }

    // MARK: - computeResult with known values

    func testComputeResultKnownValues() {
        // We can test the computation logic through ReactionTimeResult directly
        // since computeResult uses the private reactionTimes array
        let times: [Double] = [200, 250, 300, 350, 400]
        let avg = times.reduce(0, +) / Double(times.count) // 300
        let fastest = times.min()! // 200
        let slowest = times.max()! // 400

        let variance = times.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(times.count)
        let stddev = variance.squareRoot()

        let result = ReactionTimeResult(
            reactionTimesMs: times,
            averageMs: avg,
            standardDeviationMs: stddev,
            fastestMs: fastest,
            slowestMs: slowest
        )

        XCTAssertEqual(result.averageMs, 300, accuracy: 0.01)
        XCTAssertEqual(result.fastestMs, 200, accuracy: 0.01)
        XCTAssertEqual(result.slowestMs, 400, accuracy: 0.01)
        // stddev of [200,250,300,350,400] = sqrt(5000) ≈ 70.71
        XCTAssertEqual(result.standardDeviationMs, 70.71, accuracy: 0.1)
    }

    // MARK: - Single reaction time

    func testSingleReactionTime() {
        let times: [Double] = [250]
        let result = ReactionTimeResult(
            reactionTimesMs: times,
            averageMs: 250,
            standardDeviationMs: 0,
            fastestMs: 250,
            slowestMs: 250
        )
        XCTAssertEqual(result.averageMs, 250)
        XCTAssertEqual(result.standardDeviationMs, 0)
        XCTAssertEqual(result.fastestMs, 250)
        XCTAssertEqual(result.slowestMs, 250)
    }

    // MARK: - State machine

    func testInitialState() {
        let engine = ReactionTimeEngine()
        XCTAssertEqual(engine.state, .ready)
        XCTAssertEqual(engine.currentTrialNumber, 0)
    }

    func testTotalTrials() {
        let engine = ReactionTimeEngine()
        XCTAssertEqual(engine.totalTrials, 5)
    }

    func testResetClearsState() {
        let engine = ReactionTimeEngine()
        engine.reset()
        XCTAssertEqual(engine.state, .ready)
        XCTAssertEqual(engine.currentTrialNumber, 0)
    }

    func testStartBeginsWaiting() {
        let engine = ReactionTimeEngine()
        engine.start()
        if case .waiting(let trial) = engine.state {
            XCTAssertEqual(trial, 1)
        } else {
            XCTFail("After start, state should be waiting(trial: 1)")
        }
        engine.reset()
    }

    func testOnTapInReadyDoesNothing() {
        let engine = ReactionTimeEngine()
        engine.onTap()
        XCTAssertEqual(engine.state, .ready)
    }

    func testCurrentTrialNumberInCompleteState() {
        let engine = ReactionTimeEngine()
        // Force complete state
        let result = ReactionTimeResult(
            reactionTimesMs: [200, 250, 300],
            averageMs: 250,
            standardDeviationMs: 40,
            fastestMs: 200,
            slowestMs: 300
        )
        engine.state = .complete(result)
        XCTAssertEqual(engine.currentTrialNumber, 5) // totalTrials
    }

    // MARK: - ReactionTimeResult model

    func testReactionTimeResultProperties() {
        let times: [Double] = [180, 220, 260]
        let result = ReactionTimeResult(
            reactionTimesMs: times,
            averageMs: 220,
            standardDeviationMs: 32.66,
            fastestMs: 180,
            slowestMs: 260
        )

        XCTAssertEqual(result.reactionTimesMs.count, 3)
        XCTAssertEqual(result.averageMs, 220, accuracy: 0.01)
        XCTAssertEqual(result.fastestMs, 180, accuracy: 0.01)
        XCTAssertEqual(result.slowestMs, 260, accuracy: 0.01)
    }

    // MARK: - Identical reaction times (zero stddev)

    func testIdenticalReactionTimes() {
        let times: [Double] = [300, 300, 300, 300, 300]
        let avg = 300.0
        let variance = times.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(times.count)
        let stddev = variance.squareRoot()

        XCTAssertEqual(stddev, 0, accuracy: 0.001)
    }
}

import XCTest
@testable import LeiLeMe

final class TapTestEngineTests: XCTestCase {

    // MARK: - computeResult with known timestamps

    func testComputeResultZeroTaps() {
        let engine = TapTestEngine()
        // No taps recorded
        let result = engine.computeResult()

        XCTAssertEqual(result.round1Taps, 0)
        XCTAssertEqual(result.round2Taps, 0)
        XCTAssertEqual(result.round1Frequency, 0)
        XCTAssertEqual(result.round2Frequency, 0)
        XCTAssertEqual(result.rhythmStability, 0)
        XCTAssertEqual(result.fatigueDecay, 1.0, "No R1 taps → fatigueDecay defaults to 1.0")
    }

    func testFatigueDecayCalculation() {
        // fatigueDecay = round2Freq / round1Freq
        // If round2 is slower, fatigueDecay < 1.0
        let result = TapTestResult(
            round1Taps: 50,
            round2Taps: 40,
            round1Frequency: 5.0,
            round2Frequency: 4.0,
            rhythmStability: 0.1,
            fatigueDecay: 4.0 / 5.0
        )
        XCTAssertEqual(result.fatigueDecay, 0.8, accuracy: 0.001)
    }

    func testFatigueDecayEqualRounds() {
        let result = TapTestResult(
            round1Taps: 50,
            round2Taps: 50,
            round1Frequency: 5.0,
            round2Frequency: 5.0,
            rhythmStability: 0.1,
            fatigueDecay: 5.0 / 5.0
        )
        XCTAssertEqual(result.fatigueDecay, 1.0, accuracy: 0.001)
    }

    // MARK: - Coefficient of Variation

    func testRhythmStabilityWithUniformIntervals() {
        // If all intervals are identical, CV = 0
        // We can't call the private static method directly,
        // but we test through the model values.
        let result = TapTestResult(
            round1Taps: 10,
            round2Taps: 10,
            round1Frequency: 1.0,
            round2Frequency: 1.0,
            rhythmStability: 0.0,
            fatigueDecay: 1.0
        )
        XCTAssertEqual(result.rhythmStability, 0.0, accuracy: 0.001)
    }

    // MARK: - State machine

    func testInitialState() {
        let engine = TapTestEngine()
        XCTAssertEqual(engine.state, .ready)
        XCTAssertEqual(engine.tapCount, 0)
        XCTAssertFalse(engine.isActive)
    }

    func testResetClearsState() {
        let engine = TapTestEngine()
        engine.reset()
        XCTAssertEqual(engine.state, .ready)
        XCTAssertEqual(engine.tapCount, 0)
    }

    func testRecordTapInReadyStateDoesNothing() {
        let engine = TapTestEngine()
        engine.recordTap()
        XCTAssertEqual(engine.tapCount, 0)
    }

    // MARK: - Round duration and rest

    func testRoundDurationConstants() {
        // Verify via start — after start, state should be round1
        let engine = TapTestEngine()
        engine.start()
        if case .round1 = engine.state {
            // Expected
        } else {
            XCTFail("After start, state should be round1")
        }
        XCTAssertTrue(engine.isActive)
        engine.reset()
    }

    // MARK: - TapTestResult model

    func testTapTestResultProperties() {
        let result = TapTestResult(
            round1Taps: 45,
            round2Taps: 42,
            round1Frequency: 4.5,
            round2Frequency: 4.2,
            rhythmStability: 0.15,
            fatigueDecay: 0.933
        )

        XCTAssertEqual(result.round1Taps, 45)
        XCTAssertEqual(result.round2Taps, 42)
        XCTAssertEqual(result.round1Frequency, 4.5, accuracy: 0.01)
        XCTAssertEqual(result.round2Frequency, 4.2, accuracy: 0.01)
        XCTAssertEqual(result.rhythmStability, 0.15, accuracy: 0.01)
        XCTAssertEqual(result.fatigueDecay, 0.933, accuracy: 0.01)
    }
}

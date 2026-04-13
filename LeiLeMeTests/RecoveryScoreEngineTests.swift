import XCTest
import SwiftData
@testable import LeiLeMe

final class RecoveryScoreEngineTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "dominantHand")
        container = try TestHelpers.makeContainer()
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        UserDefaults.standard.removeObject(forKey: "dominantHand")
    }

    // MARK: - Baseline building period (< 3 days)

    @MainActor
    func testBaselineBuildingReturnsNeutral() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 50, rhrBaseline: 60, sleepDurationBaseline: 7,
            tapFrequencyBaseline: 5, rhythmStabilityBaseline: 0.1,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 2  // < 3
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.status, .neutral)
        XCTAssertEqual(result.availableDimensions, 0)
    }

    // MARK: - At baseline (score ≈ 100)

    @MainActor
    func testAtBaselineScoreIs100() throws {
        let assessment = TestHelpers.makeFullAssessment(
            daysAgo: 0, in: context,
            hrv: 45, rhr: 60, sleepDuration: 7.5,
            tapR1Freq: 5.0, tapR2Freq: 4.8,
            rhythmStability: 0.12,
            reactionAvg: 300, reactionSD: 20,
            sleepQuality: 4, muscleSoreness: 4, energyLevel: 4
        )

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertEqual(result.score, 100, accuracy: 2.0, "Score should be ~100 when today matches baseline")
        XCTAssertEqual(result.availableDimensions, 9)
        XCTAssertEqual(result.totalDimensions, 10)
    }

    // MARK: - Better than baseline (score > 100)

    @MainActor
    func testBetterThanBaseline() throws {
        let assessment = TestHelpers.makeFullAssessment(
            daysAgo: 0, in: context,
            hrv: 60,        // higher = better
            rhr: 50,        // lower = better
            sleepDuration: 9,
            tapR1Freq: 6.0, tapR2Freq: 5.8,
            rhythmStability: 0.08,  // lower = better
            reactionAvg: 250,       // lower = better
            sleepQuality: 5, muscleSoreness: 5, energyLevel: 5
        )

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertGreaterThan(result.score, 100, "Better-than-baseline should score > 100")
        XCTAssertEqual(result.status, .good)
    }

    // MARK: - Worse than baseline (score < 100)

    @MainActor
    func testWorseThanBaseline() throws {
        let assessment = TestHelpers.makeFullAssessment(
            daysAgo: 0, in: context,
            hrv: 25,        // much lower
            rhr: 80,        // much higher
            sleepDuration: 4,
            tapR1Freq: 3.0, tapR2Freq: 2.8,
            rhythmStability: 0.25,
            reactionAvg: 500,
            sleepQuality: 2, muscleSoreness: 2, energyLevel: 2
        )

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertLessThan(result.score, 70, "Much worse than baseline should score < 70")
        XCTAssertEqual(result.status, .needsAttention)
    }

    // MARK: - Score clamped to 120

    @MainActor
    func testScoreClampedAt120() throws {
        // Extremely good day — all values vastly better
        let assessment = TestHelpers.makeFullAssessment(
            daysAgo: 0, in: context,
            hrv: 200,
            rhr: 30,
            sleepDuration: 14,
            tapR1Freq: 12.0, tapR2Freq: 11.0,
            rhythmStability: 0.01,
            reactionAvg: 100,
            sleepQuality: 5, muscleSoreness: 5, energyLevel: 5
        )

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 40, rhrBaseline: 65, sleepDurationBaseline: 6,
            tapFrequencyBaseline: 4, rhythmStabilityBaseline: 0.2,
            reactionTimeBaseline: 350, reactionConsistencyBaseline: 30,
            sleepQualityBaseline: 3, sorenessBaseline: 3, energyBaseline: 3,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertLessThanOrEqual(result.score, 120, "Score should be clamped at 120")
    }

    // MARK: - No measures available (all nil)

    @MainActor
    func testNoMeasuresAvailable() throws {
        // Assessment with zero measures
        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)
        try context.save()

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.status, .neutral)
        XCTAssertEqual(result.availableDimensions, 0)
    }

    // MARK: - Partial measures (weight redistribution)

    @MainActor
    func testPartialMeasuresRedistributeWeight() throws {
        // Only HRV available
        let assessment = TestHelpers.makeAssessment(daysAgo: 0, hrv: 45, in: context)

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        // With only HRV and today==baseline, score should be ~100
        XCTAssertEqual(result.score, 100, accuracy: 1.0)
        XCTAssertEqual(result.availableDimensions, 1)
    }

    // MARK: - Zero baseline value (division by zero)

    @MainActor
    func testZeroBaselineSkipsDimension() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context, hrv: 50)

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 0,    // zero baseline — should be skipped via guard base > 0
            rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        // Should not crash. HRV dimension is skipped (base=0).
        XCTAssertGreaterThanOrEqual(result.score, 0)
    }

    // MARK: - Nil baseline (dimension skipped)

    @MainActor
    func testNilBaselineSkipsDimension() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: nil,    // no baseline
            rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        XCTAssertEqual(result.availableDimensions, 8, "HRV should be excluded")
    }

    // MARK: - Status thresholds

    @MainActor
    func testModerateStatus() throws {
        // Create an assessment slightly below baseline for moderate (70-90)
        let assessment = TestHelpers.makeFullAssessment(
            daysAgo: 0, in: context,
            hrv: 36,       // ~80% of baseline
            rhr: 72,       // ~120% of baseline (worse)
            sleepDuration: 6.0,
            tapR1Freq: 4.0, tapR2Freq: 3.8,
            rhythmStability: 0.15,
            reactionAvg: 360,
            sleepQuality: 3, muscleSoreness: 3, energyLevel: 3
        )

        let baseline = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
        // This should be in the moderate range
        XCTAssertGreaterThanOrEqual(result.score, 70)
        XCTAssertLessThan(result.score, 90)
        XCTAssertEqual(result.status, .moderate)
    }

    // MARK: - Dimension count

    func test_dimensionCount_isTen() {
        XCTAssertEqual(RecoveryScoreEngine.dimensionCount, 10)
    }

    // MARK: - Grip strength dimension

    @MainActor
    func test_evaluate_includesGripStrengthDimension() throws {
        UserSettings.dominantHand = .right

        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)
        let reading = GripStrengthReading(valueKg: 50, hand: .right)
        context.insert(reading)
        assessment.gripStrengthReadings.append(reading)
        try context.save()

        let baseline = BaselineEngine.BaselineSnapshot(
            gripStrengthBaseline: 45,
            hrvBaseline: nil,
            rhrBaseline: nil,
            sleepDurationBaseline: nil,
            tapFrequencyBaseline: nil,
            rhythmStabilityBaseline: nil,
            reactionTimeBaseline: nil,
            reactionConsistencyBaseline: nil,
            sleepQualityBaseline: nil,
            sorenessBaseline: nil,
            energyBaseline: nil,
            dayCount: 5
        )

        let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)

        XCTAssertEqual(result.availableDimensions, 1)
        XCTAssertEqual(result.score, (50.0 / 45.0) * 100.0, accuracy: 0.5)
    }
}

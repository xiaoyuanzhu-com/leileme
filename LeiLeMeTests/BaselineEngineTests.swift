import XCTest
import SwiftData
@testable import LeiLeMe

final class BaselineEngineTests: XCTestCase {

    private var engine: BaselineEngine!
    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        engine = BaselineEngine()
        container = try TestHelpers.makeContainer()
        context = container.mainContext
    }

    override func tearDown() {
        engine = nil
        container = nil
        context = nil
    }

    // MARK: - Empty data

    func testEmptyAssessments() {
        let snapshot = engine.computeBaseline(from: [])
        XCTAssertEqual(snapshot.dayCount, 0)
        XCTAssertNil(snapshot.hrvBaseline)
        XCTAssertNil(snapshot.rhrBaseline)
        XCTAssertNil(snapshot.sleepDurationBaseline)
        XCTAssertNil(snapshot.tapFrequencyBaseline)
        XCTAssertNil(snapshot.rhythmStabilityBaseline)
        XCTAssertNil(snapshot.reactionTimeBaseline)
        XCTAssertNil(snapshot.reactionConsistencyBaseline)
        XCTAssertNil(snapshot.sleepQualityBaseline)
        XCTAssertNil(snapshot.sorenessBaseline)
        XCTAssertNil(snapshot.energyBaseline)
    }

    // MARK: - Single data point

    @MainActor
    func testSingleAssessment() throws {
        let a = TestHelpers.makeFullAssessment(daysAgo: 1, in: context, hrv: 50, rhr: 65)
        let snapshot = engine.computeBaseline(from: [a])

        XCTAssertEqual(snapshot.dayCount, 1)
        XCTAssertEqual(snapshot.hrvBaseline!, 50, accuracy: 0.01)
        XCTAssertEqual(snapshot.rhrBaseline!, 65, accuracy: 0.01)
    }

    // MARK: - 7-day window (only recent data counts)

    @MainActor
    func testOnlyLast7DaysIncluded() throws {
        let old = TestHelpers.makeFullAssessment(daysAgo: 8, in: context, hrv: 100)
        let recent = TestHelpers.makeFullAssessment(daysAgo: 3, in: context, hrv: 40)

        let snapshot = engine.computeBaseline(from: [old, recent])
        XCTAssertEqual(snapshot.dayCount, 1, "Only the recent assessment should count")
        XCTAssertEqual(snapshot.hrvBaseline!, 40, accuracy: 0.01)
    }

    // MARK: - Today excluded

    @MainActor
    func testTodayExcluded() throws {
        let _ = TestHelpers.makeFullAssessment(daysAgo: 0, in: context, hrv: 100)
        let snapshot = engine.computeBaseline(from: [TestHelpers.makeFullAssessment(daysAgo: 0, in: context, hrv: 100)])

        XCTAssertEqual(snapshot.dayCount, 0)
        XCTAssertNil(snapshot.hrvBaseline)
    }

    // MARK: - Averaging

    @MainActor
    func testAveraging() throws {
        let a1 = TestHelpers.makeFullAssessment(daysAgo: 1, in: context, hrv: 40, rhr: 60, sleepDuration: 7.0)
        let a2 = TestHelpers.makeFullAssessment(daysAgo: 2, in: context, hrv: 50, rhr: 70, sleepDuration: 8.0)
        let a3 = TestHelpers.makeFullAssessment(daysAgo: 3, in: context, hrv: 60, rhr: 80, sleepDuration: 6.0)

        let snapshot = engine.computeBaseline(from: [a1, a2, a3])

        XCTAssertEqual(snapshot.dayCount, 3)
        XCTAssertEqual(snapshot.hrvBaseline!, 50, accuracy: 0.01)
        XCTAssertEqual(snapshot.rhrBaseline!, 70, accuracy: 0.01)
        XCTAssertEqual(snapshot.sleepDurationBaseline!, 7.0, accuracy: 0.01)
    }

    // MARK: - Partial measures (some nil)

    @MainActor
    func testPartialMeasures() throws {
        let a = TestHelpers.makeAssessment(daysAgo: 1, hrv: 55, in: context)

        let snapshot = engine.computeBaseline(from: [a])
        XCTAssertEqual(snapshot.dayCount, 1)
        XCTAssertEqual(snapshot.hrvBaseline!, 55, accuracy: 0.01)
        XCTAssertNil(snapshot.tapFrequencyBaseline)
        XCTAssertNil(snapshot.reactionTimeBaseline)
        XCTAssertNil(snapshot.sleepQualityBaseline)
    }

    // MARK: - Tap test averaging

    @MainActor
    func testTapTestBaseline() throws {
        let a = TestHelpers.makeAssessment(
            daysAgo: 1,
            tapR1Freq: 6.0, tapR2Freq: 4.0,
            rhythmStability: 0.15,
            in: context
        )
        let snapshot = engine.computeBaseline(from: [a])

        XCTAssertEqual(snapshot.tapFrequencyBaseline!, 5.0, accuracy: 0.01)
        XCTAssertEqual(snapshot.rhythmStabilityBaseline!, 0.15, accuracy: 0.001)
    }

    // MARK: - Reaction time baseline

    @MainActor
    func testReactionTimeBaseline() throws {
        let a1 = TestHelpers.makeAssessment(daysAgo: 1, reactionAvg: 280, reactionSD: 15, in: context)
        let a2 = TestHelpers.makeAssessment(daysAgo: 2, reactionAvg: 320, reactionSD: 25, in: context)

        let snapshot = engine.computeBaseline(from: [a1, a2])
        XCTAssertEqual(snapshot.reactionTimeBaseline!, 300, accuracy: 0.01)
        XCTAssertEqual(snapshot.reactionConsistencyBaseline!, 20, accuracy: 0.01)
    }

    // MARK: - Subjective baseline

    @MainActor
    func testSubjectiveBaseline() throws {
        let a1 = TestHelpers.makeAssessment(
            daysAgo: 1,
            sleepQuality: 3, muscleSoreness: 4, energyLevel: 5,
            in: context
        )
        let a2 = TestHelpers.makeAssessment(
            daysAgo: 2,
            sleepQuality: 5, muscleSoreness: 2, energyLevel: 3,
            in: context
        )

        let snapshot = engine.computeBaseline(from: [a1, a2])
        XCTAssertEqual(snapshot.sleepQualityBaseline!, 4.0, accuracy: 0.01)
        XCTAssertEqual(snapshot.sorenessBaseline!, 3.0, accuracy: 0.01)
        XCTAssertEqual(snapshot.energyBaseline!, 4.0, accuracy: 0.01)
    }

    // MARK: - Full 7-day window

    @MainActor
    func testFull7DayWindow() throws {
        var assessments: [DailyAssessment] = []
        for day in 1...7 {
            let a = TestHelpers.makeFullAssessment(daysAgo: day, in: context, hrv: Double(40 + day))
            assessments.append(a)
        }
        let snapshot = engine.computeBaseline(from: assessments)
        XCTAssertEqual(snapshot.dayCount, 7)
        XCTAssertEqual(snapshot.hrvBaseline!, 44.0, accuracy: 0.01)
    }
}

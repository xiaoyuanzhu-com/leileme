import XCTest
import SwiftData
@testable import LeiLeMe

final class MeasureTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        container = try TestHelpers.makeContainer()
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - Measure enum coverage

    func testAllMeasuresCount() {
        XCTAssertEqual(Measure.allCases.count, 9)
    }

    func testMeasureTypes() {
        XCTAssertEqual(Measure.hrvSDNN.type, .healthKit)
        XCTAssertEqual(Measure.restingHeartRate.type, .healthKit)
        XCTAssertEqual(Measure.sleepDuration.type, .healthKit)
        XCTAssertEqual(Measure.tapFrequency.type, .activeTest)
        XCTAssertEqual(Measure.tapStability.type, .activeTest)
        XCTAssertEqual(Measure.reactionTime.type, .activeTest)
        XCTAssertEqual(Measure.sleepQuality.type, .subjective)
        XCTAssertEqual(Measure.muscleSoreness.type, .subjective)
        XCTAssertEqual(Measure.energyLevel.type, .subjective)
    }

    func testHigherIsBetter() {
        XCTAssertTrue(Measure.hrvSDNN.higherIsBetter)
        XCTAssertFalse(Measure.restingHeartRate.higherIsBetter)
        XCTAssertTrue(Measure.sleepDuration.higherIsBetter)
        XCTAssertTrue(Measure.tapFrequency.higherIsBetter)
        XCTAssertFalse(Measure.tapStability.higherIsBetter)
        XCTAssertFalse(Measure.reactionTime.higherIsBetter)
        XCTAssertTrue(Measure.sleepQuality.higherIsBetter)
        XCTAssertTrue(Measure.muscleSoreness.higherIsBetter)
        XCTAssertTrue(Measure.energyLevel.higherIsBetter)
    }

    // MARK: - DailyAssessment.value(for:)

    @MainActor
    func testValueForHealthKitMeasures() throws {
        let assessment = TestHelpers.makeAssessment(
            daysAgo: 0, hrv: 50, rhr: 65, sleepDuration: 7.5, in: context
        )

        XCTAssertEqual(assessment.value(for: .hrvSDNN), 50)
        XCTAssertEqual(assessment.value(for: .restingHeartRate), 65)
        XCTAssertEqual(assessment.value(for: .sleepDuration), 7.5)
    }

    @MainActor
    func testValueForTapMeasures() throws {
        let assessment = TestHelpers.makeAssessment(
            daysAgo: 0,
            tapR1Freq: 5.0, tapR2Freq: 4.0,
            rhythmStability: 0.15,
            in: context
        )

        // tapFrequency = (r1 + r2) / 2
        XCTAssertEqual(assessment.value(for: .tapFrequency)!, 4.5, accuracy: 0.01)
        XCTAssertEqual(assessment.value(for: .tapStability)!, 0.15, accuracy: 0.001)
    }

    @MainActor
    func testValueForReactionTime() throws {
        let assessment = TestHelpers.makeAssessment(
            daysAgo: 0, reactionAvg: 280, in: context
        )

        XCTAssertEqual(assessment.value(for: .reactionTime)!, 280, accuracy: 0.01)
    }

    @MainActor
    func testValueForSubjectiveMeasures() throws {
        let assessment = TestHelpers.makeAssessment(
            daysAgo: 0,
            sleepQuality: 4, muscleSoreness: 3, energyLevel: 5,
            in: context
        )

        XCTAssertEqual(assessment.value(for: .sleepQuality), 4)
        XCTAssertEqual(assessment.value(for: .muscleSoreness), 3)
        XCTAssertEqual(assessment.value(for: .energyLevel), 5)
    }

    @MainActor
    func testValueForMissingMeasures() throws {
        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)
        try context.save()

        for measure in Measure.allCases {
            XCTAssertNil(assessment.value(for: measure), "\(measure) should be nil when no data")
        }
    }

    // MARK: - Subjective zero values treated as nil

    @MainActor
    func testSubjectiveZeroTreatedAsNil() throws {
        let assessment = TestHelpers.makeAssessment(
            daysAgo: 0,
            sleepQuality: 0, muscleSoreness: 0, energyLevel: 0,
            in: context
        )

        XCTAssertNil(assessment.value(for: .sleepQuality), "Zero sleep quality should be nil")
        XCTAssertNil(assessment.value(for: .muscleSoreness), "Zero soreness should be nil")
        XCTAssertNil(assessment.value(for: .energyLevel), "Zero energy should be nil")
    }

    // MARK: - BaselineSnapshot.value(for:)

    func testBaselineSnapshotValueExtraction() {
        let snapshot = BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )

        XCTAssertEqual(snapshot.value(for: .hrvSDNN), 45)
        XCTAssertEqual(snapshot.value(for: .restingHeartRate), 60)
        XCTAssertEqual(snapshot.value(for: .sleepDuration), 7.5)
        XCTAssertEqual(snapshot.value(for: .tapFrequency), 4.9)
        XCTAssertEqual(snapshot.value(for: .tapStability), 0.12)
        XCTAssertEqual(snapshot.value(for: .reactionTime), 300)
        XCTAssertEqual(snapshot.value(for: .sleepQuality), 4)
        XCTAssertEqual(snapshot.value(for: .muscleSoreness), 4)
        XCTAssertEqual(snapshot.value(for: .energyLevel), 4)
    }

    // MARK: - SubjectiveAssessment.update

    @MainActor
    func testSubjectiveAssessmentUpdate() throws {
        let sub = SubjectiveAssessment(sleepQuality: 3, muscleSoreness: 3, energyLevel: 3)
        context.insert(sub)

        sub.update(measure: .sleepQuality, value: 5)
        XCTAssertEqual(sub.sleepQuality, 5)
        XCTAssertEqual(sub.muscleSoreness, 3, "Other fields unchanged")

        sub.update(measure: .muscleSoreness, value: 1)
        XCTAssertEqual(sub.muscleSoreness, 1)

        sub.update(measure: .energyLevel, value: 4)
        XCTAssertEqual(sub.energyLevel, 4)
    }

    @MainActor
    func testSubjectiveAssessmentUpdateNonSubjectiveMeasureDoesNothing() throws {
        let sub = SubjectiveAssessment(sleepQuality: 3, muscleSoreness: 3, energyLevel: 3)
        context.insert(sub)

        sub.update(measure: .hrvSDNN, value: 99)
        XCTAssertEqual(sub.sleepQuality, 3)
        XCTAssertEqual(sub.muscleSoreness, 3)
        XCTAssertEqual(sub.energyLevel, 3)
    }
}

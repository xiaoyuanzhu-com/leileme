import XCTest
import SwiftData
@testable import LeiLeMe

final class WeeklyInsightsServiceTests: XCTestCase {

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

    // MARK: - Not enough data (< 7 days)

    @MainActor
    func testFewerThan7DaysReturnsNil() throws {
        var assessments: [DailyAssessment] = []
        for day in 1...6 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)
        XCTAssertNil(insight, "Fewer than 7 past assessments should return nil")
    }

    // MARK: - Exactly 7 days: this week only

    @MainActor
    func testExactly7DaysProducesInsight() throws {
        var assessments: [DailyAssessment] = []
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight!.thisWeekDayCount, 7)
        XCTAssertNil(insight!.lastWeekAverage, "No last week data")
        XCTAssertNil(insight!.deltaPercent)
    }

    // MARK: - Two weeks of data

    @MainActor
    func testTwoWeeksShowsDelta() throws {
        var assessments: [DailyAssessment] = []
        // This week: days 1-7
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }
        // Last week: days 8-14
        for day in 8...14 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        XCTAssertNotNil(insight!.lastWeekAverage)
        XCTAssertNotNil(insight!.deltaPercent)
    }

    // MARK: - Best and worst day

    @MainActor
    func testBestAndWorstDay() throws {
        var assessments: [DailyAssessment] = []
        // Day 1: great (high HRV, low RHR)
        assessments.append(TestHelpers.makeFullAssessment(
            daysAgo: 1, in: context,
            hrv: 70, rhr: 50, sleepDuration: 9,
            tapR1Freq: 6.0, tapR2Freq: 5.8,
            reactionAvg: 220,
            sleepQuality: 5, muscleSoreness: 5, energyLevel: 5
        ))
        // Days 2-6: average
        for day in 2...6 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }
        // Day 7: poor
        assessments.append(TestHelpers.makeFullAssessment(
            daysAgo: 7, in: context,
            hrv: 25, rhr: 80, sleepDuration: 4,
            tapR1Freq: 3.0, tapR2Freq: 2.5,
            reactionAvg: 500,
            sleepQuality: 1, muscleSoreness: 1, energyLevel: 1
        ))

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        XCTAssertNotNil(insight!.bestDay)
        XCTAssertNotNil(insight!.worstDay)
        XCTAssertGreaterThan(insight!.bestDay!.score, insight!.worstDay!.score)
    }

    // MARK: - Partial week

    @MainActor
    func testPartialWeekHandled() throws {
        var assessments: [DailyAssessment] = []
        // Only 3 days this week + 7 filler older days to pass the >=7 total gate
        for day in 1...3 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }
        for day in 8...11 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight!.thisWeekDayCount, 3)
        XCTAssertTrue(insight!.summary.contains("3"))
    }

    // MARK: - Per-dimension trends

    @MainActor
    func testPerDimensionTrendsCount() throws {
        var assessments: [DailyAssessment] = []
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        XCTAssertEqual(insight!.perDimensionTrends.count, Measure.allCases.count)
    }

    // MARK: - Today excluded

    @MainActor
    func testTodayExcluded() throws {
        var assessments: [DailyAssessment] = []
        // Include today
        assessments.append(TestHelpers.makeFullAssessment(daysAgo: 0, in: context, hrv: 999))
        // And 7 past days
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        // The extreme HRV=999 from today should not appear in the insights
        XCTAssertEqual(insight!.thisWeekDayCount, 7)
    }

    // MARK: - Dimension deltas: improvement

    @MainActor
    func testDimensionDeltasImprovement() throws {
        var assessments: [DailyAssessment] = []
        // This week: better HRV
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context, hrv: 60))
        }
        // Last week: worse HRV
        for day in 8...14 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context, hrv: 40))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)

        XCTAssertNotNil(insight)
        // topImproving should exist — HRV improved by 50%
        XCTAssertNotNil(insight!.topImproving)
    }

    // MARK: - Empty this week returns nil

    @MainActor
    func testEmptyThisWeekReturnsNil() throws {
        var assessments: [DailyAssessment] = []
        // Only old data (> 7 days ago, some >= 7 total)
        for day in 8...15 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        let baseline = makeBaseline(dayCount: 7)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)
        XCTAssertNil(insight, "No this-week assessments should return nil")
    }

    // MARK: - Baseline building period: scores are 0

    @MainActor
    func testBaselineBuildingPeriodScoresZero() throws {
        var assessments: [DailyAssessment] = []
        for day in 1...7 {
            assessments.append(TestHelpers.makeFullAssessment(daysAgo: day, in: context))
        }

        // With dayCount < 3, all scores will be 0 → no valid scores → nil
        let baseline = makeBaseline(dayCount: 2)
        let insight = WeeklyInsightsService.compute(assessments: assessments, baseline: baseline)
        XCTAssertNil(insight, "During baseline building, all scores are 0 and should be filtered out")
    }

    // MARK: - Helper

    private func makeBaseline(dayCount: Int) -> BaselineEngine.BaselineSnapshot {
        BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: dayCount
        )
    }
}

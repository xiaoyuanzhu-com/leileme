import XCTest
import SwiftData
@testable import LeiLeMe

final class StreakTrackerTests: XCTestCase {

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

    // MARK: - Helper: get/set the persisted StreakRecord

    @MainActor
    private func fetchRecord() -> StreakRecord? {
        let descriptor = FetchDescriptor<StreakRecord>()
        return (try? context.fetch(descriptor))?.first
    }

    @MainActor
    private func setStreak(current: Int, lastActive daysAgo: Int, graceUsed: Bool) {
        // The tracker creates a record on init. Modify that record.
        if let record = fetchRecord() {
            record.currentStreak = current
            record.lastActiveDate = dayStart(daysAgo: daysAgo)
            record.graceUsed = graceUsed
            try? context.save()
        }
    }

    // MARK: - Initial state

    @MainActor
    func testInitialStreakIsZero() throws {
        let tracker = StreakTracker(modelContext: context)
        XCTAssertEqual(tracker.currentStreak, 0)
        XCTAssertFalse(tracker.graceUsed)
    }

    // MARK: - First activity

    @MainActor
    func testFirstActivityStartsStreakAtOne() throws {
        let tracker = StreakTracker(modelContext: context)
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [assessment])
        XCTAssertEqual(tracker.currentStreak, 1)
    }

    // MARK: - Consecutive days

    @MainActor
    func testConsecutiveDaysIncrementStreak() throws {
        let tracker = StreakTracker(modelContext: context)
        // Simulate existing streak: 3 days, last active yesterday
        setStreak(current: 3, lastActive: 1, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 4)
    }

    // MARK: - Grace period: 1 day missed

    @MainActor
    func testOneDayMissedUsesGracePeriod() throws {
        let tracker = StreakTracker(modelContext: context)
        // Last active was 2 days ago (1 day gap)
        setStreak(current: 5, lastActive: 2, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 6, "Streak should continue with grace period")
        XCTAssertTrue(tracker.graceUsed)
    }

    // MARK: - Grace already used + 1 day missed -> reset

    @MainActor
    func testGraceAlreadyUsedThenMissedResetsStreak() throws {
        let tracker = StreakTracker(modelContext: context)
        // Last active was 2 days ago, grace already used
        setStreak(current: 5, lastActive: 2, graceUsed: true)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 1, "Streak should reset when grace already used")
        XCTAssertFalse(tracker.graceUsed)
    }

    // MARK: - 2+ days missed -> reset

    @MainActor
    func testTwoDaysMissedResetsStreak() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 10, lastActive: 3, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 1, "Streak should reset after 2+ days missed")
    }

    // MARK: - No data today: streak alive check

    @MainActor
    func testNoDataTodayStreakStillAlive() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 5, lastActive: 1, graceUsed: false)

        // No today assessment
        tracker.refresh(assessments: [])

        XCTAssertEqual(tracker.currentStreak, 5, "Streak should remain if yesterday was active")
    }

    // MARK: - No data today: streak broken after 2 days

    @MainActor
    func testNoDataTodayStreakBrokenAfterLongGap() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 5, lastActive: 3, graceUsed: false)

        tracker.refresh(assessments: [])

        XCTAssertEqual(tracker.currentStreak, 0, "Streak should break after 3+ day gap")
    }

    // MARK: - Milestones

    @MainActor
    func testMilestoneAt3Days() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 2, lastActive: 1, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 3)
        XCTAssertNotNil(tracker.milestoneMessage)
    }

    @MainActor
    func testMilestoneAt7Days() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 6, lastActive: 1, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 7)
        XCTAssertNotNil(tracker.milestoneMessage)
    }

    @MainActor
    func testNoMilestoneAt5Days() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 4, lastActive: 1, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 5)
        XCTAssertNil(tracker.milestoneMessage)
    }

    // MARK: - Same day refresh idempotent

    @MainActor
    func testSameDayRefreshIdempotent() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 3, lastActive: 0, graceUsed: false)

        let todayAssessment = TestHelpers.makeFullAssessment(daysAgo: 0, in: context)
        tracker.refresh(assessments: [todayAssessment])

        XCTAssertEqual(tracker.currentStreak, 3, "Refreshing on same day should not change streak")
    }

    // MARK: - Grace period with no data today: 2 day gap, grace unused

    @MainActor
    func testGracePeriodCoversToday() throws {
        let tracker = StreakTracker(modelContext: context)
        setStreak(current: 5, lastActive: 2, graceUsed: false)

        // No data today
        tracker.refresh(assessments: [])

        XCTAssertEqual(tracker.currentStreak, 5, "Grace period should keep streak alive for one skipped day")
    }

    // MARK: - Helper

    private func dayStart(daysAgo: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
    }
}

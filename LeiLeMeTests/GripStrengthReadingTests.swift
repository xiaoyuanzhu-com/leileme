import XCTest
import SwiftData
@testable import LeiLeMe

final class GripStrengthReadingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dominantHand")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dominantHand")
        super.tearDown()
    }

    func test_init_storesValueHandAndTimestamp() {
        let ts = Date(timeIntervalSince1970: 1_700_000_000)
        let reading = GripStrengthReading(valueKg: 42.5, hand: .right, timestamp: ts)

        XCTAssertEqual(reading.valueKg, 42.5)
        XCTAssertEqual(reading.hand, "right")
        XCTAssertEqual(reading.timestamp, ts)
    }

    func test_init_defaultsTimestampToNow() {
        let before = Date()
        let reading = GripStrengthReading(valueKg: 30, hand: .left)
        let after = Date()

        XCTAssertGreaterThanOrEqual(reading.timestamp, before)
        XCTAssertLessThanOrEqual(reading.timestamp, after)
    }

    @MainActor
    func test_canBeInsertedIntoSwiftDataContainer() throws {
        let container = try ModelContainer(
            for: GripStrengthReading.self, DailyAssessment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let reading = GripStrengthReading(valueKg: 45, hand: .right)
        context.insert(reading)
        try context.save()

        let descriptor = FetchDescriptor<GripStrengthReading>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.valueKg, 45)
    }

    @MainActor
    func test_dailyAssessment_startsWithEmptyGripReadings() throws {
        let container = try ModelContainer(
            for: DailyAssessment.self, GripStrengthReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)
        try context.save()

        XCTAssertEqual(assessment.gripStrengthReadings.count, 0)
    }

    @MainActor
    func test_dailyAssessment_appendingGripReadingPersists() throws {
        let container = try ModelContainer(
            for: DailyAssessment.self, GripStrengthReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)

        let reading = GripStrengthReading(valueKg: 40, hand: .right)
        context.insert(reading)
        assessment.gripStrengthReadings.append(reading)
        try context.save()

        let descriptor = FetchDescriptor<DailyAssessment>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.first?.gripStrengthReadings.count, 1)
        XCTAssertEqual(fetched.first?.gripStrengthReadings.first?.valueKg, 40)
    }

    @MainActor
    func test_dailyAssessment_deletingAssessmentCascadesReadings() throws {
        let container = try ModelContainer(
            for: DailyAssessment.self, GripStrengthReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)
        let reading = GripStrengthReading(valueKg: 40, hand: .right)
        context.insert(reading)
        assessment.gripStrengthReadings.append(reading)
        try context.save()

        context.delete(assessment)
        try context.save()

        let readings = try context.fetch(FetchDescriptor<GripStrengthReading>())
        XCTAssertEqual(readings.count, 0, "cascade delete should remove child readings")
    }

}

// MARK: - Aggregation rule

final class GripStrengthAggregationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "dominantHand")
        container = try ModelContainer(
            for: DailyAssessment.self, GripStrengthReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dominantHand")
        container = nil
        context = nil
    }

    @MainActor
    private func makeAssessmentWithReadings(
        _ readings: [(valueKg: Double, hand: Hand, offsetSeconds: TimeInterval)]
    ) throws -> DailyAssessment {
        let assessment = DailyAssessment(date: Date())
        context.insert(assessment)

        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        for r in readings {
            let reading = GripStrengthReading(
                valueKg: r.valueKg,
                hand: r.hand,
                timestamp: anchor.addingTimeInterval(r.offsetSeconds)
            )
            context.insert(reading)
            assessment.gripStrengthReadings.append(reading)
        }
        try context.save()
        return assessment
    }

    @MainActor
    func test_gripValue_returnsNil_whenNoReadings() throws {
        UserSettings.dominantHand = .right
        let assessment = try makeAssessmentWithReadings([])
        XCTAssertNil(assessment.value(for: .gripStrength))
    }

    @MainActor
    func test_gripValue_returnsNil_whenOnlyNonDominantReadings() throws {
        UserSettings.dominantHand = .right
        let assessment = try makeAssessmentWithReadings([
            (40, .left, 0),
            (42, .left, 100)
        ])
        XCTAssertNil(assessment.value(for: .gripStrength))
    }

    @MainActor
    func test_gripValue_returnsLatestDominantHandReading() throws {
        UserSettings.dominantHand = .right
        let assessment = try makeAssessmentWithReadings([
            (38, .right, 0),
            (42, .right, 300),
            (40, .right, 100)
        ])
        XCTAssertEqual(assessment.value(for: .gripStrength), 42)
    }

    @MainActor
    func test_gripValue_ignoresNonDominantWhenDominantPresent() throws {
        UserSettings.dominantHand = .right
        let assessment = try makeAssessmentWithReadings([
            (45, .left, 500),
            (40, .right, 100)
        ])
        XCTAssertEqual(assessment.value(for: .gripStrength), 40)
    }

    @MainActor
    func test_gripValue_respectsDominantHandSetting() throws {
        UserSettings.dominantHand = .left
        defer { UserSettings.dominantHand = .right }

        let assessment = try makeAssessmentWithReadings([
            (45, .left, 500),
            (40, .right, 100)
        ])
        XCTAssertEqual(assessment.value(for: .gripStrength), 45)
    }
}

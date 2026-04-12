import XCTest
import SwiftData
@testable import LeiLeMe

final class GripStrengthReadingTests: XCTestCase {

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
}

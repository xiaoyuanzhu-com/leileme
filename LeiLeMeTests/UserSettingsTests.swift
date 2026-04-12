import XCTest
@testable import LeiLeMe

final class UserSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dominantHand")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dominantHand")
        super.tearDown()
    }

    func test_dominantHand_defaultsToRight_whenUnset() {
        XCTAssertEqual(UserSettings.dominantHand, .right)
    }

    func test_dominantHand_defaultsToRight_whenGarbageStored() {
        UserDefaults.standard.set("ambidextrous", forKey: "dominantHand")
        XCTAssertEqual(UserSettings.dominantHand, .right)
    }

    func test_dominantHand_roundTripsLeft() {
        UserSettings.dominantHand = .left
        XCTAssertEqual(UserSettings.dominantHand, .left)
    }

    func test_dominantHand_roundTripsRight() {
        UserSettings.dominantHand = .left
        UserSettings.dominantHand = .right
        XCTAssertEqual(UserSettings.dominantHand, .right)
    }
}

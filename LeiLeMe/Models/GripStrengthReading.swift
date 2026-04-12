import Foundation
import SwiftData

@Model
final class GripStrengthReading {
    var valueKg: Double
    var hand: String
    var timestamp: Date
    var assessment: DailyAssessment?

    init(valueKg: Double, hand: Hand, timestamp: Date = Date()) {
        self.valueKg = valueKg
        self.hand = hand.rawValue
        self.timestamp = timestamp
    }
}

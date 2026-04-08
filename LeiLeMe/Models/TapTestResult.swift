import Foundation
import SwiftData

@Model
final class TapTestResult {
    var round1Taps: Int
    var round2Taps: Int
    var round1Frequency: Double
    var round2Frequency: Double
    var rhythmStability: Double
    var fatigueDecay: Double
    var recordedAt: Date

    init(
        round1Taps: Int,
        round2Taps: Int,
        round1Frequency: Double,
        round2Frequency: Double,
        rhythmStability: Double,
        fatigueDecay: Double,
        recordedAt: Date = Date()
    ) {
        self.round1Taps = round1Taps
        self.round2Taps = round2Taps
        self.round1Frequency = round1Frequency
        self.round2Frequency = round2Frequency
        self.rhythmStability = rhythmStability
        self.fatigueDecay = fatigueDecay
        self.recordedAt = recordedAt
    }
}

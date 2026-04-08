import Foundation
import SwiftData

@Model
final class ReactionTimeResult {
    var reactionTimesMs: [Double]
    var averageMs: Double
    var standardDeviationMs: Double
    var fastestMs: Double
    var slowestMs: Double
    var recordedAt: Date

    init(
        reactionTimesMs: [Double],
        averageMs: Double,
        standardDeviationMs: Double,
        fastestMs: Double,
        slowestMs: Double,
        recordedAt: Date = Date()
    ) {
        self.reactionTimesMs = reactionTimesMs
        self.averageMs = averageMs
        self.standardDeviationMs = standardDeviationMs
        self.fastestMs = fastestMs
        self.slowestMs = slowestMs
        self.recordedAt = recordedAt
    }
}

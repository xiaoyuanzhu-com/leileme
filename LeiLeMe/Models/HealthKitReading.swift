import Foundation
import SwiftData

@Model
final class HealthKitReading {
    var hrvSDNN: Double?
    var restingHeartRate: Double?
    var sleepDuration: Double?
    var sleepQuality: String?
    var recordedAt: Date

    init(
        hrvSDNN: Double? = nil,
        restingHeartRate: Double? = nil,
        sleepDuration: Double? = nil,
        sleepQuality: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.hrvSDNN = hrvSDNN
        self.restingHeartRate = restingHeartRate
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.recordedAt = recordedAt
    }

}

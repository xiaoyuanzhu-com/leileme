import Foundation
import SwiftData

@Model
final class HealthKitReading {
    var hrvRMSSD: Double?
    var restingHeartRate: Double?
    var sleepDuration: Double?
    var sleepQuality: String?
    var recordedAt: Date

    init(
        hrvRMSSD: Double? = nil,
        restingHeartRate: Double? = nil,
        sleepDuration: Double? = nil,
        sleepQuality: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.hrvRMSSD = hrvRMSSD
        self.restingHeartRate = restingHeartRate
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.recordedAt = recordedAt
    }
}

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

    /// Backward-compatible alias while ResultView still references the old name.
    /// Remove once ResultView is updated (T0017).
    var hrvRMSSD: Double? {
        get { hrvSDNN }
        set { hrvSDNN = newValue }
    }

    /// Backward-compatible convenience init for callers still using hrvRMSSD parameter name.
    /// Remove once all call sites are updated.
    convenience init(
        hrvRMSSD: Double?,
        restingHeartRate: Double? = nil,
        sleepDuration: Double? = nil,
        sleepQuality: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.init(
            hrvSDNN: hrvRMSSD,
            restingHeartRate: restingHeartRate,
            sleepDuration: sleepDuration,
            sleepQuality: sleepQuality,
            recordedAt: recordedAt
        )
    }
}

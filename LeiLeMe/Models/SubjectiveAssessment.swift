import Foundation
import SwiftData

@Model
final class SubjectiveAssessment {
    var sleepQuality: Int
    var muscleSoreness: Int
    var energyLevel: Int
    var recordedAt: Date

    init(
        sleepQuality: Int,
        muscleSoreness: Int,
        energyLevel: Int,
        recordedAt: Date = Date()
    ) {
        self.sleepQuality = sleepQuality
        self.muscleSoreness = muscleSoreness
        self.energyLevel = energyLevel
        self.recordedAt = recordedAt
    }
}

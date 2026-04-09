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

    /// Update a single subjective field by measure, preserving the others.
    func update(measure: Measure, value: Int) {
        switch measure {
        case .sleepQuality:
            sleepQuality = value
        case .muscleSoreness:
            muscleSoreness = value
        case .energyLevel:
            energyLevel = value
        default:
            break
        }
        recordedAt = Date()
    }
}

import Foundation
import SwiftData

@Model
final class DailyAssessment {
    var date: Date
    @Relationship(deleteRule: .cascade) var healthKitData: HealthKitReading?
    @Relationship(deleteRule: .cascade) var tapTestResult: TapTestResult?
    @Relationship(deleteRule: .cascade) var reactionTimeResult: ReactionTimeResult?
    @Relationship(deleteRule: .cascade) var subjectiveAssessment: SubjectiveAssessment?
    var createdAt: Date

    init(
        date: Date,
        healthKitData: HealthKitReading? = nil,
        tapTestResult: TapTestResult? = nil,
        reactionTimeResult: ReactionTimeResult? = nil,
        subjectiveAssessment: SubjectiveAssessment? = nil,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.healthKitData = healthKitData
        self.tapTestResult = tapTestResult
        self.reactionTimeResult = reactionTimeResult
        self.subjectiveAssessment = subjectiveAssessment
        self.createdAt = createdAt
    }
}

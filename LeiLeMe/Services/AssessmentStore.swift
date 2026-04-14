import Foundation
import SwiftData

@Observable
class AssessmentStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Get or create today's DailyAssessment

    func todayAssessment() -> DailyAssessment {
        if let existing = fetchTodayAssessment() {
            return existing
        }
        let assessment = DailyAssessment(date: Calendar.current.startOfDay(for: Date()))
        modelContext.insert(assessment)
        try? modelContext.save()
        return assessment
    }

    func fetchTodayAssessment() -> DailyAssessment? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let descriptor = FetchDescriptor<DailyAssessment>(
            predicate: #Predicate<DailyAssessment> { assessment in
                assessment.date >= startOfToday && assessment.date < endOfToday
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Save individual measures

    func saveHealthKitReading(_ reading: HealthKitReading) {
        let assessment = todayAssessment()
        if let existing = assessment.healthKitData {
            // Update existing reading in place
            existing.hrvSDNN = reading.hrvSDNN
            existing.restingHeartRate = reading.restingHeartRate
            existing.sleepDuration = reading.sleepDuration
            existing.sleepQuality = reading.sleepQuality
            existing.recordedAt = Date()
        } else {
            modelContext.insert(reading)
            assessment.healthKitData = reading
        }
        try? modelContext.save()
    }

    func saveTapTestResult(_ result: TapTestResult) {
        let assessment = todayAssessment()
        if let old = assessment.tapTestResult { modelContext.delete(old) }
        modelContext.insert(result)
        assessment.tapTestResult = result
        try? modelContext.save()
    }

    func saveReactionTimeResult(_ result: ReactionTimeResult) {
        let assessment = todayAssessment()
        if let old = assessment.reactionTimeResult { modelContext.delete(old) }
        modelContext.insert(result)
        assessment.reactionTimeResult = result
        try? modelContext.save()
    }

    func saveSubjectiveRating(measure: Measure, value: Int) {
        let assessment = todayAssessment()

        if let existing = assessment.subjectiveAssessment {
            existing.update(measure: measure, value: value)
        } else {
            let subjective = SubjectiveAssessment(
                sleepQuality: 0,
                muscleSoreness: 0,
                energyLevel: 0
            )
            subjective.update(measure: measure, value: value)
            modelContext.insert(subjective)
            assessment.subjectiveAssessment = subjective
        }
        try? modelContext.save()
    }

    func addGripStrengthReading(valueKg: Double, hand: Hand, timestamp: Date = Date()) {
        let assessment = todayAssessment()
        let reading = GripStrengthReading(valueKg: valueKg, hand: hand, timestamp: timestamp)
        modelContext.insert(reading)
        assessment.gripStrengthReadings.append(reading)
        try? modelContext.save()
    }

    func deleteGripStrengthReading(_ reading: GripStrengthReading) {
        modelContext.delete(reading)
        try? modelContext.save()
    }

    // MARK: - Query helpers

    func hasDataToday(for measure: Measure) -> Bool {
        todayValue(for: measure) != nil
    }

    func todayValue(for measure: Measure) -> Double? {
        fetchTodayAssessment()?.value(for: measure)
    }
}

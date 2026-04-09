import Foundation

/// Defines all 9 tracked measures with their metadata.
enum MeasureType: String, Codable {
    case healthKit
    case activeTest
    case subjective
}

enum Measure: String, CaseIterable, Identifiable {
    case hrvSDNN
    case restingHeartRate
    case sleepDuration
    case tapFrequency
    case tapStability
    case reactionTime
    case sleepQuality
    case muscleSoreness
    case energyLevel

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hrvSDNN:           return "HRV (SDNN)"
        case .restingHeartRate:  return "Resting Heart Rate"
        case .sleepDuration:     return "Sleep Duration"
        case .tapFrequency:      return "Tap Frequency"
        case .tapStability:      return "Tap Stability"
        case .reactionTime:      return "Reaction Time"
        case .sleepQuality:      return "Sleep Quality"
        case .muscleSoreness:    return "Muscle Soreness"
        case .energyLevel:       return "Energy Level"
        }
    }

    var icon: String {
        switch self {
        case .hrvSDNN:           return "waveform.path.ecg"
        case .restingHeartRate:  return "heart.fill"
        case .sleepDuration:     return "bed.double.fill"
        case .tapFrequency:      return "hand.tap.fill"
        case .tapStability:      return "metronome.fill"
        case .reactionTime:      return "bolt.fill"
        case .sleepQuality:      return "moon.fill"
        case .muscleSoreness:    return "figure.walk"
        case .energyLevel:       return "flame.fill"
        }
    }

    var unit: String {
        switch self {
        case .hrvSDNN:           return "ms"
        case .restingHeartRate:  return "bpm"
        case .sleepDuration:     return "hrs"
        case .tapFrequency:      return "taps/s"
        case .tapStability:      return "cv"
        case .reactionTime:      return "ms"
        case .sleepQuality:      return "/5"
        case .muscleSoreness:    return "/5"
        case .energyLevel:       return "/5"
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .hrvSDNN:           return true
        case .restingHeartRate:  return false
        case .sleepDuration:     return true
        case .tapFrequency:      return true
        case .tapStability:      return false   // lower CV = more stable
        case .reactionTime:      return false   // lower = faster
        case .sleepQuality:      return true
        case .muscleSoreness:    return true    // higher = less sore (1=very sore, 5=none)
        case .energyLevel:       return true
        }
    }

    var type: MeasureType {
        switch self {
        case .hrvSDNN, .restingHeartRate, .sleepDuration:
            return .healthKit
        case .tapFrequency, .tapStability, .reactionTime:
            return .activeTest
        case .sleepQuality, .muscleSoreness, .energyLevel:
            return .subjective
        }
    }

    var formatString: String {
        switch self {
        case .hrvSDNN:           return "%.0f"
        case .restingHeartRate:  return "%.0f"
        case .sleepDuration:     return "%.1f"
        case .tapFrequency:      return "%.1f"
        case .tapStability:      return "%.3f"
        case .reactionTime:      return "%.0f"
        case .sleepQuality:      return "%.0f"
        case .muscleSoreness:    return "%.0f"
        case .energyLevel:       return "%.0f"
        }
    }

    var promptText: String {
        switch type {
        case .healthKit:   return "Tap to sync"
        case .activeTest:  return "Tap to test"
        case .subjective:  return "Tap to rate"
        }
    }
}

// MARK: - DailyAssessment value extraction

extension DailyAssessment {
    /// Extract today's value for a given measure.
    func value(for measure: Measure) -> Double? {
        switch measure {
        case .hrvSDNN:
            return healthKitData?.hrvSDNN
        case .restingHeartRate:
            return healthKitData?.restingHeartRate
        case .sleepDuration:
            return healthKitData?.sleepDuration
        case .tapFrequency:
            guard let tap = tapTestResult else { return nil }
            return (tap.round1Frequency + tap.round2Frequency) / 2.0
        case .tapStability:
            return tapTestResult?.rhythmStability
        case .reactionTime:
            return reactionTimeResult?.averageMs
        case .sleepQuality:
            return subjectiveAssessment.map { Double($0.sleepQuality) }
        case .muscleSoreness:
            return subjectiveAssessment.map { Double($0.muscleSoreness) }
        case .energyLevel:
            return subjectiveAssessment.map { Double($0.energyLevel) }
        }
    }
}

// MARK: - BaselineSnapshot value extraction

extension BaselineEngine.BaselineSnapshot {
    /// Extract the baseline value for a given measure.
    func value(for measure: Measure) -> Double? {
        switch measure {
        case .hrvSDNN:           return hrvBaseline
        case .restingHeartRate:  return rhrBaseline
        case .sleepDuration:     return sleepDurationBaseline
        case .tapFrequency:      return tapFrequencyBaseline
        case .tapStability:      return rhythmStabilityBaseline
        case .reactionTime:      return reactionTimeBaseline
        case .sleepQuality:      return sleepQualityBaseline
        case .muscleSoreness:    return sorenessBaseline
        case .energyLevel:       return energyBaseline
        }
    }
}

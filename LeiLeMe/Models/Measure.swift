import Foundation

/// Defines all 10 tracked measures with their metadata.
enum MeasureType: String, Codable {
    case healthKit
    case activeTest
    case subjective
    case manualLog
}

enum Measure: String, CaseIterable, Identifiable {
    case gripStrength
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
        case .gripStrength:      return String(localized: "measure.gripStrength.name")
        case .hrvSDNN:           return String(localized: "measure.hrvSDNN.name")
        case .restingHeartRate:  return String(localized: "measure.restingHeartRate.name")
        case .sleepDuration:     return String(localized: "measure.sleepDuration.name")
        case .tapFrequency:      return String(localized: "measure.tapFrequency.name")
        case .tapStability:      return String(localized: "measure.tapStability.name")
        case .reactionTime:      return String(localized: "measure.reactionTime.name")
        case .sleepQuality:      return String(localized: "measure.sleepQuality.name")
        case .muscleSoreness:    return String(localized: "measure.muscleSoreness.name")
        case .energyLevel:       return String(localized: "measure.energyLevel.name")
        }
    }

    var icon: String {
        switch self {
        case .gripStrength:      return "hand.raised.fill"
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
        case .gripStrength:      return String(localized: "measure.unit.kg")
        case .hrvSDNN:           return String(localized: "measure.unit.ms")
        case .restingHeartRate:  return String(localized: "measure.unit.bpm")
        case .sleepDuration:     return String(localized: "measure.unit.hrs")
        case .tapFrequency:      return String(localized: "measure.unit.tapsPerSec")
        case .tapStability:      return String(localized: "measure.unit.cv")
        case .reactionTime:      return String(localized: "measure.unit.ms")
        case .sleepQuality:      return String(localized: "measure.unit.outOf5")
        case .muscleSoreness:    return String(localized: "measure.unit.outOf5")
        case .energyLevel:       return String(localized: "measure.unit.outOf5")
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .gripStrength:      return true
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
        case .gripStrength:
            return .manualLog
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
        case .gripStrength:      return "%.1f"
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
        case .healthKit:   return String(localized: "measure.prompt.sync")
        case .activeTest:  return String(localized: "measure.prompt.test")
        case .subjective:  return String(localized: "measure.prompt.rate")
        case .manualLog:   return String(localized: "measure.prompt.log")
        }
    }
}

// MARK: - DailyAssessment value extraction

extension DailyAssessment {
    /// Extract today's value for a given measure.
    func value(for measure: Measure) -> Double? {
        switch measure {
        case .gripStrength:
            let dominant = UserSettings.dominantHand
            let onDominant = gripStrengthReadings.filter { $0.hand == dominant.rawValue }
            guard let latest = onDominant.max(by: { $0.timestamp < $1.timestamp }) else {
                return nil
            }
            return latest.valueKg
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
            guard let sub = subjectiveAssessment, sub.sleepQuality > 0 else { return nil }
            return Double(sub.sleepQuality)
        case .muscleSoreness:
            guard let sub = subjectiveAssessment, sub.muscleSoreness > 0 else { return nil }
            return Double(sub.muscleSoreness)
        case .energyLevel:
            guard let sub = subjectiveAssessment, sub.energyLevel > 0 else { return nil }
            return Double(sub.energyLevel)
        }
    }
}

// MARK: - BaselineSnapshot value extraction

extension BaselineEngine.BaselineSnapshot {
    /// Extract the baseline value for a given measure.
    func value(for measure: Measure) -> Double? {
        switch measure {
        case .gripStrength:      return gripStrengthBaseline
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

// MARK: - Description

extension Measure {
    var description: String {
        switch self {
        case .gripStrength:     return String(localized: "measure.gripStrength.description")
        case .hrvSDNN:          return String(localized: "measure.hrvSDNN.description")
        case .restingHeartRate: return String(localized: "measure.restingHeartRate.description")
        case .sleepDuration:    return String(localized: "measure.sleepDuration.description")
        case .tapFrequency:     return String(localized: "measure.tapFrequency.description")
        case .tapStability:     return String(localized: "measure.tapStability.description")
        case .reactionTime:     return String(localized: "measure.reactionTime.description")
        case .sleepQuality:     return String(localized: "measure.sleepQuality.description")
        case .muscleSoreness:   return String(localized: "measure.muscleSoreness.description")
        case .energyLevel:      return String(localized: "measure.energyLevel.description")
        }
    }
}

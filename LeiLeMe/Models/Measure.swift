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

// MARK: - Description

extension Measure {
    var description: String {
        switch self {
        case .hrvSDNN:
            return "Heart rate variability measures the tiny differences in timing between each heartbeat \u{2014} a sign of how well your body\u{2019}s rest-and-recover system is working. It\u{2019}s considered the gold standard for recovery tracking. A higher value means your nervous system is more resilient and ready to handle stress."
        case .restingHeartRate:
            return "Your resting heart rate is how many times your heart beats per minute when you\u{2019}re fully at rest. When it\u{2019}s lower than your usual baseline, your cardiovascular system is well recovered. An elevated reading often signals that stress, illness, or incomplete recovery is putting extra load on your body."
        case .sleepDuration:
            return "This is the total hours of sleep recorded from your phone or watch. Sleep is when your body does most of its repair work \u{2014} muscles rebuild, hormones rebalance, and memories consolidate. Most adults need 7\u{2013}9 hours, and more sleep generally means better recovery."
        case .tapFrequency:
            return "This measures how fast you can tap in a quick 10-second test, which reveals how efficiently your brain is sending signals to your muscles. Think of it as a readiness check for your motor system. If you\u{2019}re tapping slower than your baseline, your nervous system may be fatigued."
        case .tapStability:
            return "While tap frequency checks speed, stability checks rhythm \u{2014} how evenly spaced your taps are. A steady, consistent rhythm means your nervous system has good fine motor control. When you\u{2019}re fatigued, your tapping becomes more erratic even if you don\u{2019}t feel tired."
        case .reactionTime:
            return "This measures how quickly you respond to something appearing on screen \u{2014} a direct window into your alertness and cognitive sharpness. Slower reactions than your baseline usually point to sleep debt, mental fatigue, or incomplete recovery."
        case .sleepQuality:
            return "Your own rating of how well you slept, from restless to deeply refreshing. This captures things that hours alone can\u{2019}t \u{2014} like whether you woke up multiple times, had vivid dreams, or simply feel unrested despite a full night."
        case .muscleSoreness:
            return "A quick self-check on how your muscles feel right now. Higher ratings mean less soreness. Persistent or unusual soreness is your body\u{2019}s way of saying your muscles have not fully repaired yet and could benefit from lighter activity or rest."
        case .energyLevel:
            return "A simple rating of how much energy you feel you have right now. This intuitive gut check often picks up on things the objective tests miss \u{2014} like emotional stress, motivation, or coming down with something. Higher means you feel more ready to go."
        }
    }
}

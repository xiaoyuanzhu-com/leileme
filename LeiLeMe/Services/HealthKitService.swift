import Foundation
import HealthKit

@Observable
final class HealthKitService {

    // MARK: - State

    var isAuthorized: Bool = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Private

    private let healthStore = HKHealthStore()

    private let readTypes: Set<HKSampleType> = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKCategoryType(.sleepAnalysis),
    ]

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - HRV

    /// Fetch the most recent HRV (SDNN) sample from the last 24 hours.
    func fetchLatestHRV() async throws -> Double? {
        let quantityType = HKQuantityType(.heartRateVariabilitySDNN)
        let sample = try await fetchMostRecentSample(of: quantityType, within: .hours(24))
        guard let sample else { return nil }
        return sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }

    // MARK: - Resting Heart Rate

    /// Fetch the most recent resting heart rate sample from the last 24 hours.
    func fetchLatestRestingHeartRate() async throws -> Double? {
        let quantityType = HKQuantityType(.restingHeartRate)
        let sample = try await fetchMostRecentSample(of: quantityType, within: .hours(24))
        guard let sample else { return nil }
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        return sample.quantity.doubleValue(for: bpmUnit)
    }

    // MARK: - Sleep

    /// Fetch last night's sleep analysis. Returns total sleep duration (hours) and a quality string.
    func fetchLastNightSleep() async throws -> (duration: Double?, quality: String?) {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current

        // Look back from now to 8 PM yesterday to cover a full night.
        let now = Date()
        guard let yesterday8PM = calendar.date(
            bySettingHour: 20, minute: 0, second: 0,
            of: calendar.date(byAdding: .day, value: -1, to: now)!
        ) else {
            return (nil, nil)
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday8PM,
            end: now,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        let samples = try await descriptor.result(for: healthStore)

        guard !samples.isEmpty else { return (nil, nil) }

        // Accumulate durations by sleep stage.
        var asleepSeconds: TimeInterval = 0
        var deepSeconds: TimeInterval = 0
        var remSeconds: TimeInterval = 0
        var coreSeconds: TimeInterval = 0
        var awakeSeconds: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)

            switch value {
            case .asleepDeep:
                deepSeconds += duration
                asleepSeconds += duration
            case .asleepREM:
                remSeconds += duration
                asleepSeconds += duration
            case .asleepCore:
                coreSeconds += duration
                asleepSeconds += duration
            case .asleepUnspecified, .asleep:
                asleepSeconds += duration
            case .awake:
                awakeSeconds += duration
            case .inBed:
                break // Don't count time merely in bed.
            @unknown default:
                break
            }
        }

        let totalHours = asleepSeconds / 3600.0

        guard totalHours > 0 else { return (nil, nil) }

        // Assess quality based on sleep stages.
        let quality = assessSleepQuality(
            totalSleep: asleepSeconds,
            deep: deepSeconds,
            rem: remSeconds,
            core: coreSeconds,
            awake: awakeSeconds
        )

        return (totalHours, quality)
    }

    // MARK: - Convenience

    /// Fetch all available health data and return a populated HealthKitReading.
    func fetchCurrentReading() async throws -> HealthKitReading {
        async let hrvResult = fetchLatestHRV()
        async let rhrResult = fetchLatestRestingHeartRate()
        async let sleepResult = fetchLastNightSleep()

        let hrv = try await hrvResult
        let rhr = try await rhrResult
        let sleep = try await sleepResult

        return HealthKitReading(
            hrvSDNN: hrv,
            restingHeartRate: rhr,
            sleepDuration: sleep.duration,
            sleepQuality: sleep.quality,
            recordedAt: Date()
        )
    }

    // MARK: - Private Helpers

    private func fetchMostRecentSample(
        of quantityType: HKQuantityType,
        within interval: DateComponents
    ) async throws -> HKQuantitySample? {
        let now = Date()
        guard let start = Calendar.current.date(byAdding: interval.negated, to: now) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        let results = try await descriptor.result(for: healthStore)
        return results.first
    }

    private func assessSleepQuality(
        totalSleep: TimeInterval,
        deep: TimeInterval,
        rem: TimeInterval,
        core: TimeInterval,
        awake: TimeInterval
    ) -> String {
        // If we have stage data, use it. Otherwise base on duration alone.
        let hasStageData = deep > 0 || rem > 0 || core > 0

        if hasStageData {
            let deepRatio = deep / totalSleep
            let remRatio = rem / totalSleep
            let awakeRatio = awake / (totalSleep + awake)

            // Good sleep: decent deep + REM, low awake time.
            if deepRatio >= 0.15 && remRatio >= 0.20 && awakeRatio < 0.10 {
                return "good"
            } else if awakeRatio > 0.20 || (deepRatio < 0.05 && remRatio < 0.10) {
                return "poor"
            } else {
                return "fair"
            }
        } else {
            // Duration-based fallback.
            let hours = totalSleep / 3600.0
            if hours >= 7.0 {
                return "good"
            } else if hours >= 5.5 {
                return "fair"
            } else {
                return "poor"
            }
        }
    }
}

// MARK: - DateComponents helper

private extension DateComponents {
    /// Returns a negated copy (e.g., +24h becomes -24h).
    var negated: DateComponents {
        var copy = DateComponents()
        if let hour { copy.hour = -hour }
        if let day { copy.day = -day }
        if let minute { copy.minute = -minute }
        if let second { copy.second = -second }
        return copy
    }

    static func hours(_ h: Int) -> DateComponents {
        DateComponents(hour: h)
    }
}

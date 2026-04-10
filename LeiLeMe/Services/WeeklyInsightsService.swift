import Foundation

/// Computes weekly recovery insights from DailyAssessment data.
struct WeeklyInsightsService {

    struct WeeklyInsight {
        let thisWeekAverage: Double
        let lastWeekAverage: Double?
        let deltaPercent: Double?       // positive = improvement
        let bestDay: DayScore?
        let worstDay: DayScore?
        let topImproving: DimensionDelta?
        let topDeclining: DimensionDelta?
        let thisWeekDayCount: Int
        let lastWeekDayCount: Int
        let summary: String
        let perDimensionTrends: [DimensionTrend]
    }

    struct DayScore: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
    }

    struct DimensionDelta: Identifiable {
        let id = UUID()
        let measure: Measure
        let thisWeekAvg: Double
        let lastWeekAvg: Double
        let deltaPercent: Double
    }

    struct DimensionTrend: Identifiable {
        let id = UUID()
        let measure: Measure
        let thisWeekAvg: Double?
        let lastWeekAvg: Double?
        let deltaPercent: Double?
        let dailyValues: [DayValue]
    }

    struct DayValue: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    // MARK: - Public

    /// Compute weekly insights. Returns nil if fewer than 7 total days of data exist.
    static func compute(
        assessments: [DailyAssessment],
        baseline: BaselineEngine.BaselineSnapshot
    ) -> WeeklyInsight? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // We need at least 7 total assessment days
        let allPastAssessments = assessments.filter { $0.date < startOfToday }
        guard allPastAssessments.count >= 7 else { return nil }

        // This week = last 7 days (not including today)
        guard let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: startOfToday) else { return nil }
        // Last week = 7 days before this week
        guard let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: startOfToday) else { return nil }

        let thisWeekAssessments = allPastAssessments.filter { $0.date >= thisWeekStart && $0.date < startOfToday }
        let lastWeekAssessments = allPastAssessments.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }

        guard !thisWeekAssessments.isEmpty else { return nil }

        // Compute daily recovery scores
        let thisWeekScores = dailyScores(for: thisWeekAssessments, baseline: baseline)
        let lastWeekScores = dailyScores(for: lastWeekAssessments, baseline: baseline)

        // Filter to days that actually have a meaningful score (> 0)
        let validThisWeek = thisWeekScores.filter { $0.score > 0 }
        let validLastWeek = lastWeekScores.filter { $0.score > 0 }

        guard !validThisWeek.isEmpty else { return nil }

        let thisAvg = validThisWeek.map(\.score).reduce(0, +) / Double(validThisWeek.count)
        let lastAvg: Double? = validLastWeek.isEmpty ? nil : validLastWeek.map(\.score).reduce(0, +) / Double(validLastWeek.count)
        let delta: Double? = lastAvg.map { lastAvg in
            guard lastAvg > 0 else { return 0 }
            return ((thisAvg - lastAvg) / lastAvg) * 100
        }

        let bestDay = validThisWeek.max(by: { $0.score < $1.score })
        let worstDay = validThisWeek.min(by: { $0.score < $1.score })

        // Per-dimension analysis
        let dimensionDeltas = computeDimensionDeltas(
            thisWeek: thisWeekAssessments,
            lastWeek: lastWeekAssessments
        )

        let topImproving = dimensionDeltas
            .filter { $0.deltaPercent > 0 }
            .max(by: { abs($0.deltaPercent) < abs($1.deltaPercent) })

        let topDeclining = dimensionDeltas
            .filter { $0.deltaPercent < 0 }
            .min(by: { $0.deltaPercent < $1.deltaPercent })

        // Per-dimension trends (for detail view)
        let trends = computeDimensionTrends(
            thisWeek: thisWeekAssessments,
            lastWeek: lastWeekAssessments
        )

        // Build natural language summary
        let summary = buildSummary(
            thisAvg: thisAvg,
            delta: delta,
            bestDay: bestDay,
            topImproving: topImproving,
            thisWeekCount: validThisWeek.count
        )

        return WeeklyInsight(
            thisWeekAverage: thisAvg,
            lastWeekAverage: lastAvg,
            deltaPercent: delta,
            bestDay: bestDay,
            worstDay: worstDay,
            topImproving: topImproving,
            topDeclining: topDeclining,
            thisWeekDayCount: validThisWeek.count,
            lastWeekDayCount: validLastWeek.count,
            summary: summary,
            perDimensionTrends: trends
        )
    }

    // MARK: - Private helpers

    private static func dailyScores(
        for assessments: [DailyAssessment],
        baseline: BaselineEngine.BaselineSnapshot
    ) -> [DayScore] {
        assessments.map { assessment in
            let result = RecoveryScoreEngine.evaluate(assessment: assessment, baseline: baseline)
            return DayScore(date: assessment.date, score: result.score)
        }
    }

    private static func computeDimensionDeltas(
        thisWeek: [DailyAssessment],
        lastWeek: [DailyAssessment]
    ) -> [DimensionDelta] {
        guard !lastWeek.isEmpty else { return [] }

        var deltas: [DimensionDelta] = []

        for measure in Measure.allCases {
            let thisValues = thisWeek.compactMap { $0.value(for: measure) }
            let lastValues = lastWeek.compactMap { $0.value(for: measure) }

            guard !thisValues.isEmpty, !lastValues.isEmpty else { continue }

            let thisAvg = thisValues.reduce(0, +) / Double(thisValues.count)
            let lastAvg = lastValues.reduce(0, +) / Double(lastValues.count)

            guard lastAvg > 0 else { continue }

            // For "higher is better" measures, positive delta = improvement
            // For "lower is better" measures, negative raw delta = improvement
            let rawDelta = ((thisAvg - lastAvg) / lastAvg) * 100
            let adjustedDelta = measure.higherIsBetter ? rawDelta : -rawDelta

            deltas.append(DimensionDelta(
                measure: measure,
                thisWeekAvg: thisAvg,
                lastWeekAvg: lastAvg,
                deltaPercent: adjustedDelta
            ))
        }

        return deltas
    }

    private static func computeDimensionTrends(
        thisWeek: [DailyAssessment],
        lastWeek: [DailyAssessment]
    ) -> [DimensionTrend] {
        Measure.allCases.map { measure in
            let thisValues = thisWeek.compactMap { a -> DayValue? in
                guard let v = a.value(for: measure) else { return nil }
                return DayValue(date: a.date, value: v)
            }
            let lastValues = lastWeek.compactMap { a -> DayValue? in
                guard let v = a.value(for: measure) else { return nil }
                return DayValue(date: a.date, value: v)
            }

            let thisAvg: Double? = thisValues.isEmpty ? nil : thisValues.map(\.value).reduce(0, +) / Double(thisValues.count)
            let lastAvg: Double? = lastValues.isEmpty ? nil : lastValues.map(\.value).reduce(0, +) / Double(lastValues.count)

            let delta: Double? = {
                guard let t = thisAvg, let l = lastAvg, l > 0 else { return nil }
                let raw = ((t - l) / l) * 100
                return measure.higherIsBetter ? raw : -raw
            }()

            // Combine all daily values for the chart
            let allValues = (lastValues + thisValues).sorted { $0.date < $1.date }

            return DimensionTrend(
                measure: measure,
                thisWeekAvg: thisAvg,
                lastWeekAvg: lastAvg,
                deltaPercent: delta,
                dailyValues: allValues
            )
        }
    }

    private static func buildSummary(
        thisAvg: Double,
        delta: Double?,
        bestDay: DayScore?,
        topImproving: DimensionDelta?,
        thisWeekCount: Int
    ) -> String {
        var parts: [String] = []

        // Main score summary
        if let delta = delta {
            let avgInt = Int(thisAvg)
            let absD = Int(abs(delta))
            if delta >= 0 {
                parts.append(String(localized: "weeklyInsights.summary.avgUp \(avgInt) \(absD)"))
            } else {
                parts.append(String(localized: "weeklyInsights.summary.avgDown \(avgInt) \(absD)"))
            }
        } else {
            parts.append(String(localized: "weeklyInsights.summary.avgOnly \(Int(thisAvg))"))
        }

        // Top improving dimension
        if let improving = topImproving {
            parts.append(String(localized: "weeklyInsights.summary.improved \(improving.measure.name)"))
        }

        // Partial week note
        if thisWeekCount < 7 {
            parts.append(String(localized: "weeklyInsights.summary.partialData \(thisWeekCount)"))
        }

        return parts.joined(separator: ". ") + "."
    }
}

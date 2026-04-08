import SwiftUI
import Charts

struct TrendChartView: View {
    let assessments: [DailyAssessment]

    @State private var selectedRange: TimeRange = .sevenDays

    enum TimeRange: String, CaseIterable {
        case sevenDays = "7 Days"
        case thirtyDays = "30 Days"

        var dayCount: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            }
        }
    }

    private var filteredAssessments: [DailyAssessment] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -selectedRange.dayCount, to: calendar.startOfDay(for: Date())) else {
            return []
        }
        return assessments
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    /// True when we have fewer than 7 days of data total (baseline still building)
    private var isBaselineBuilding: Bool {
        assessments.count < 7
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if filteredAssessments.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
            } else {
                // Early data notice when baseline is still building
                if isBaselineBuilding {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Collecting data \u{2014} baseline comparisons unlock after 7 days")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                VStack(spacing: AppSpacing.lg) {
                    chartSection(
                        title: "Tap Frequency",
                        unit: "taps/s",
                        color: .wellnessTeal,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let tap = a.tapTestResult else { return nil }
                            return ChartPoint(date: a.date, value: (tap.round1Frequency + tap.round2Frequency) / 2.0)
                        }
                    )

                    chartSection(
                        title: "Reaction Time",
                        unit: "ms",
                        color: .wellnessAmber,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let rt = a.reactionTimeResult else { return nil }
                            return ChartPoint(date: a.date, value: rt.averageMs)
                        }
                    )

                    chartSection(
                        title: "HRV (SDNN)",
                        unit: "ms",
                        color: .wellnessGreen,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let hrv = a.healthKitData?.hrvSDNN else { return nil }
                            return ChartPoint(date: a.date, value: hrv)
                        }
                    )

                    chartSection(
                        title: "Resting Heart Rate",
                        unit: "bpm",
                        color: .wellnessRed,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let rhr = a.healthKitData?.restingHeartRate else { return nil }
                            return ChartPoint(date: a.date, value: rhr)
                        }
                    )
                }

                // Subjective Trends — always available (no Apple Watch needed)
                let sleepQualityPoints = filteredAssessments.compactMap { a -> ChartPoint? in
                    guard let sub = a.subjectiveAssessment else { return nil }
                    return ChartPoint(date: a.date, value: Double(sub.sleepQuality))
                }
                let sorenessPoints = filteredAssessments.compactMap { a -> ChartPoint? in
                    guard let sub = a.subjectiveAssessment else { return nil }
                    return ChartPoint(date: a.date, value: Double(sub.muscleSoreness))
                }
                let energyPoints = filteredAssessments.compactMap { a -> ChartPoint? in
                    guard let sub = a.subjectiveAssessment else { return nil }
                    return ChartPoint(date: a.date, value: Double(sub.energyLevel))
                }

                if !sleepQualityPoints.isEmpty || !sorenessPoints.isEmpty || !energyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Subjective Trends")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, AppSpacing.sm)
                    }

                    VStack(spacing: AppSpacing.lg) {
                        chartSection(
                            title: "Sleep Quality",
                            unit: "/5",
                            color: .indigo,
                            dataPoints: sleepQualityPoints
                        )

                        chartSection(
                            title: "Muscle Soreness",
                            unit: "/5",
                            color: .orange,
                            dataPoints: sorenessPoints
                        )

                        chartSection(
                            title: "Energy Level",
                            unit: "/5",
                            color: .mint,
                            dataPoints: energyPoints
                        )
                    }
                }
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(title: String, unit: String, color: Color, dataPoints: [ChartPoint]) -> some View {
        if !dataPoints.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let latest = dataPoints.last {
                        Text("\(latest.value, specifier: title == "Tap Frequency" ? "%.1f" : "%.0f") \(unit)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(dataPoints.count < 4 ? 40 : 20)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedRange == .sevenDays ? 1 : 5)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .frame(height: 120)

                // Show point count hint for sparse data
                if dataPoints.count < 3 {
                    Text("\(dataPoints.count) data point\(dataPoints.count == 1 ? "" : "s") so far")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Chart Data Point

private struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    TrendChartView(assessments: [])
        .padding()
}

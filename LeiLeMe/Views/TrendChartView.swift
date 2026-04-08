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

    var body: some View {
        VStack(spacing: 12) {
            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if filteredAssessments.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
            } else {
                VStack(spacing: 16) {
                    chartSection(
                        title: "Tap Frequency",
                        unit: "taps/s",
                        color: .blue,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let tap = a.tapTestResult else { return nil }
                            return ChartPoint(date: a.date, value: (tap.round1Frequency + tap.round2Frequency) / 2.0)
                        }
                    )

                    chartSection(
                        title: "Reaction Time",
                        unit: "ms",
                        color: .orange,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let rt = a.reactionTimeResult else { return nil }
                            return ChartPoint(date: a.date, value: rt.averageMs)
                        }
                    )

                    chartSection(
                        title: "HRV (RMSSD)",
                        unit: "ms",
                        color: .green,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let hrv = a.healthKitData?.hrvRMSSD else { return nil }
                            return ChartPoint(date: a.date, value: hrv)
                        }
                    )

                    chartSection(
                        title: "Resting Heart Rate",
                        unit: "bpm",
                        color: .red,
                        dataPoints: filteredAssessments.compactMap { a in
                            guard let rhr = a.healthKitData?.restingHeartRate else { return nil }
                            return ChartPoint(date: a.date, value: rhr)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(title: String, unit: String, color: Color, dataPoints: [ChartPoint]) -> some View {
        if !dataPoints.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let latest = dataPoints.last {
                        Text("\(latest.value, specifier: title == "Tap Frequency" ? "%.1f" : "%.0f") \(unit)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(20)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedRange == .sevenDays ? 1 : 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 120)
                .padding(.horizontal)
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
}

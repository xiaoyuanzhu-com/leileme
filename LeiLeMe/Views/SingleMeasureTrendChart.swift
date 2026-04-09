import SwiftUI
import Charts

/// A trend chart for a single measure with 7d/30d toggle.
struct SingleMeasureTrendChart: View {
    let measure: Measure
    let dataPoints: [MeasureDataPoint]

    @State private var selectedRange: TimeRange = .sevenDays

    enum TimeRange: String, CaseIterable {
        case sevenDays = "7d"
        case thirtyDays = "30d"

        var dayCount: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            }
        }
    }

    private var filteredPoints: [MeasureDataPoint] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -selectedRange.dayCount, to: calendar.startOfDay(for: Date())) else {
            return []
        }
        return dataPoints.filter { $0.date >= cutoff }
    }

    private var chartColor: Color {
        switch measure.type {
        case .healthKit: return .wellnessGreen
        case .activeTest: return .wellnessTeal
        case .subjective: return .wellnessAmber
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if filteredPoints.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(filteredPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(measure.name, point.value)
                    )
                    .foregroundStyle(chartColor.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(measure.name, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.15), chartColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(measure.name, point.value)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(filteredPoints.count < 4 ? 40 : 20)
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
                .frame(height: 180)

                // Latest value summary
                if let latest = filteredPoints.last {
                    HStack {
                        Text("Latest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: measure.formatString, latest.value))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                            Text(measure.unit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if filteredPoints.count < 3 {
                    Text("\(filteredPoints.count) data point\(filteredPoints.count == 1 ? "" : "s") so far")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview {
    SingleMeasureTrendChart(
        measure: .hrvSDNN,
        dataPoints: [
            MeasureDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 42),
            MeasureDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 45),
            MeasureDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 38),
            MeasureDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 50),
            MeasureDataPoint(date: Date(), value: 47),
        ]
    )
    .padding()
}

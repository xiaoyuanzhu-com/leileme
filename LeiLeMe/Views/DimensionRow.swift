import SwiftUI

struct DimensionRow: View {
    let title: String
    let todayValue: Double?
    let baselineValue: Double?
    let unit: String
    let higherIsBetter: Bool
    let formatString: String
    let baselineDayCount: Int

    private var formattedToday: String {
        guard let value = todayValue else { return "\u{2014}" }
        return String(format: formatString, value)
    }

    private var formattedBaseline: String {
        guard let value = baselineValue else {
            if baselineDayCount > 0 && baselineDayCount < 7 {
                return "Building (\(baselineDayCount)/7 days)"
            }
            return "\u{2014}"
        }
        return String(format: formatString, value)
    }

    private var comparison: Comparison {
        guard let today = todayValue, let baseline = baselineValue else {
            return .neutral
        }
        let diff = today - baseline
        if abs(diff) < 0.001 {
            return .neutral
        }
        if higherIsBetter {
            return diff > 0 ? .better : .worse
        } else {
            return diff < 0 ? .better : .worse
        }
    }

    private var comparisonColor: Color {
        switch comparison {
        case .better: return .green
        case .worse: return .red
        case .neutral: return .secondary
        }
    }

    private var comparisonIcon: String {
        switch comparison {
        case .better: return "arrow.up.circle.fill"
        case .worse: return "arrow.down.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }

    /// Progress ratio for the bar: today / baseline, clamped to [0, 2].
    private var progressRatio: Double {
        guard let today = todayValue, let baseline = baselineValue, baseline > 0 else {
            return 0
        }
        return min(today / baseline, 2.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: comparisonIcon)
                    .foregroundStyle(comparisonColor)
                    .imageScale(.small)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formattedToday)
                            .font(.title3.weight(.medium).monospacedDigit())
                            .foregroundStyle(todayValue != nil ? comparisonColor : .secondary)
                        if todayValue != nil {
                            Text(unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Baseline")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formattedBaseline)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if baselineValue != nil {
                            Text(unit)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()
            }

            if todayValue != nil, baselineValue != nil {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(comparisonColor.opacity(0.7))
                            .frame(width: max(4, geometry.size.width * progressRatio / 2.0), height: 6)

                        // Baseline marker at 50%
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: 2, height: 10)
                            .offset(x: geometry.size.width / 2.0 - 1)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private enum Comparison {
        case better, worse, neutral
    }
}

#Preview {
    List {
        DimensionRow(
            title: "HRV (RMSSD)",
            todayValue: 42,
            baselineValue: 38,
            unit: "ms",
            higherIsBetter: true,
            formatString: "%.0f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Resting Heart Rate",
            todayValue: 58,
            baselineValue: 62,
            unit: "bpm",
            higherIsBetter: false,
            formatString: "%.0f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Sleep Duration",
            todayValue: nil,
            baselineValue: 7.2,
            unit: "hrs",
            higherIsBetter: true,
            formatString: "%.1f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Energy Level",
            todayValue: 3,
            baselineValue: nil,
            unit: "/5",
            higherIsBetter: true,
            formatString: "%.0f",
            baselineDayCount: 2
        )
    }
}

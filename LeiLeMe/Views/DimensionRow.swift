import SwiftUI

struct DimensionRow: View {
    let title: String
    var icon: String = ""
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

    private var isBaselineBuilding: Bool {
        baselineValue == nil && baselineDayCount > 0 && baselineDayCount < 7
    }

    private var formattedBaseline: String {
        guard let value = baselineValue else {
            if isBaselineBuilding {
                return ""  // handled by the building indicator
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
        case .better: return .statusGood
        case .worse: return .statusBad
        case .neutral: return .statusNeutral
        }
    }

    /// Arrow reflects the VALUE direction (up = value increased, down = value decreased).
    /// Color (via `comparisonColor`) stays semantic (green = good, red = bad).
    private var comparisonIcon: String {
        guard let today = todayValue, let baseline = baselineValue else {
            return "minus.circle.fill"
        }
        let diff = today - baseline
        if abs(diff) < 0.001 {
            return "minus.circle.fill"
        }
        return diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    /// Progress ratio for the bar: today / baseline, clamped to [0, 2].
    private var progressRatio: Double {
        guard let today = todayValue, let baseline = baselineValue, baseline > 0 else {
            return 0
        }
        return min(today / baseline, 2.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.wellnessTeal)
                        .frame(width: 20)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if isBaselineBuilding {
                    // Show a subtle building indicator instead of comparison arrow
                    HStack(spacing: 4) {
                        baselineDots
                        Text("building")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: comparisonIcon)
                        .foregroundStyle(comparisonColor)
                        .imageScale(.small)
                }
            }

            HStack(spacing: AppSpacing.md) {
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
                    if isBaselineBuilding {
                        BaselineBuildingLabel(dayCount: baselineDayCount)
                    } else {
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
                        Capsule()
                            .fill(Color(.systemGray3))
                            .frame(width: 2, height: 12)
                            .offset(x: geometry.size.width / 2.0 - 1)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Baseline Building Dots

    /// Seven small dots showing how many days are filled
    private var baselineDots: some View {
        HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index < baselineDayCount ? Color.wellnessTeal : Color(.systemGray4))
                    .frame(width: 4, height: 4)
            }
        }
    }

    private enum Comparison {
        case better, worse, neutral
    }
}

// MARK: - Baseline Building Label

private struct BaselineBuildingLabel: View {
    let dayCount: Int

    var body: some View {
        HStack(spacing: 4) {
            // Mini progress dots
            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(index < dayCount ? Color.wellnessTeal : Color(.systemGray5))
                        .frame(width: 6, height: 3)
                }
            }
            Text("\(dayCount)/7")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DimensionRow(
            title: "HRV (SDNN)",
            icon: "waveform.path.ecg",
            todayValue: 42,
            baselineValue: 38,
            unit: "ms",
            higherIsBetter: true,
            formatString: "%.0f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Resting Heart Rate",
            icon: "heart.fill",
            todayValue: 58,
            baselineValue: 62,
            unit: "bpm",
            higherIsBetter: false,
            formatString: "%.0f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Sleep Duration",
            icon: "bed.double.fill",
            todayValue: nil,
            baselineValue: 7.2,
            unit: "hrs",
            higherIsBetter: true,
            formatString: "%.1f",
            baselineDayCount: 7
        )
        DimensionRow(
            title: "Energy Level",
            icon: "bolt.fill",
            todayValue: 3,
            baselineValue: nil,
            unit: "/5",
            higherIsBetter: true,
            formatString: "%.0f",
            baselineDayCount: 2
        )
    }
    .padding()
}

import SwiftUI

/// A compact weekly insights card shown on the Home page below the recovery card area.
/// Only visible when 7+ days of assessment data exist.
struct WeeklyInsightsCard: View {
    let insight: WeeklyInsightsService.WeeklyInsight

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Compact card — always visible
            compactContent
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }

            // Expanded detail — inline
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppSpacing.md)

                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Compact

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.wellnessBlue)

                Text(String(localized: "weeklyInsights.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            // Natural language summary
            Text(insight.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Stats row
            HStack(spacing: AppSpacing.md) {
                // Average score
                statBadge(
                    label: String(localized: "weeklyInsights.avg"),
                    value: "\(Int(insight.thisWeekAverage))",
                    delta: insight.deltaPercent
                )

                // Best day
                if let best = insight.bestDay {
                    statBadge(
                        label: String(localized: "weeklyInsights.best"),
                        value: "\(Int(best.score))",
                        subtitle: shortDay(best.date)
                    )
                }

                // Worst day
                if let worst = insight.worstDay {
                    statBadge(
                        label: String(localized: "weeklyInsights.worst"),
                        value: "\(Int(worst.score))",
                        subtitle: shortDay(worst.date)
                    )
                }

                Spacer()
            }

            // Dimension highlights
            HStack(spacing: AppSpacing.md) {
                if let improving = insight.topImproving {
                    dimensionChip(
                        icon: "arrow.up.right",
                        name: improving.measure.name,
                        color: .statusGood
                    )
                }
                if let declining = insight.topDeclining {
                    dimensionChip(
                        icon: "arrow.down.right",
                        name: declining.measure.name,
                        color: .statusWarning
                    )
                }
                Spacer()
            }
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "weeklyInsights.perDimension"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(insight.perDimensionTrends.filter { $0.thisWeekAvg != nil }) { trend in
                dimensionRow(trend)
            }

            if insight.thisWeekDayCount < 7 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text(String(localized: "weeklyInsights.partialWeek \(insight.thisWeekDayCount)"))
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Components

    private func statBadge(
        label: String,
        value: String,
        delta: Double? = nil,
        subtitle: String? = nil
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)

                if let delta = delta {
                    deltaArrow(delta)
                }
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deltaArrow(_ delta: Double) -> some View {
        HStack(spacing: 1) {
            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2.weight(.bold))
            Text("\(Int(abs(delta)))%")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(delta >= 0 ? Color.statusGood : Color.statusWarning)
    }

    private func dimensionChip(icon: String, name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }

    private func dimensionRow(_ trend: WeeklyInsightsService.DimensionTrend) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: trend.measure.icon)
                .font(.caption)
                .foregroundStyle(measureColor(trend.measure))
                .frame(width: 20)

            Text(trend.measure.name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            if let thisAvg = trend.thisWeekAvg {
                Text(String(format: trend.measure.formatString, thisAvg))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)

                Text(trend.measure.unit)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let delta = trend.deltaPercent {
                deltaArrow(delta)
                    .frame(width: 48, alignment: .trailing)
            } else {
                Text("--")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func measureColor(_ measure: Measure) -> Color {
        switch measure.type {
        case .healthKit: return .wellnessGreen
        case .activeTest: return .wellnessTeal
        case .subjective: return .wellnessAmber
        case .manualLog: return .wellnessBlue
        }
    }
}

#Preview {
    WeeklyInsightsCard(
        insight: WeeklyInsightsService.WeeklyInsight(
            thisWeekAverage: 72,
            lastWeekAverage: 64,
            deltaPercent: 12.5,
            bestDay: .init(date: Date().addingTimeInterval(-86400 * 2), score: 88),
            worstDay: .init(date: Date().addingTimeInterval(-86400 * 5), score: 55),
            topImproving: .init(measure: .sleepQuality, thisWeekAvg: 4.2, lastWeekAvg: 3.5, deltaPercent: 20),
            topDeclining: .init(measure: .reactionTime, thisWeekAvg: 320, lastWeekAvg: 290, deltaPercent: -10.3),
            thisWeekDayCount: 7,
            lastWeekDayCount: 7,
            summary: "Your recovery averaged 72 this week, up 12% from last week. Sleep Quality improved the most.",
            perDimensionTrends: []
        )
    )
    .padding()
}

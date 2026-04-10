import SwiftUI

/// A card displaying a single measure's current state: no data, today's data, or stale.
struct MeasureCard: View {
    let measure: Measure
    let todayValue: Double?
    let baselineValue: Double?
    let lastValue: Double?
    let lastDate: Date?
    let hasHistory: Bool
    /// Whether HealthKit authorization has been requested (for graceful no-data messaging).
    var healthKitAuthRequested: Bool = false

    /// Visual state of the card.
    private enum CardState {
        case noData
        case hasToday
        case stale
    }

    private var state: CardState {
        if todayValue != nil {
            return .hasToday
        } else if hasHistory {
            return .stale
        } else {
            return .noData
        }
    }

    // MARK: - Delta computation

    private var deltaPercent: Double? {
        guard let today = todayValue, let baseline = baselineValue, baseline > 0 else {
            return nil
        }
        return ((today - baseline) / baseline) * 100.0
    }

    /// Whether the delta is favorable given the measure's polarity.
    private var deltaIsGood: Bool {
        guard let delta = deltaPercent else { return true }
        return measure.higherIsBetter ? delta >= 0 : delta <= 0
    }

    private var deltaColor: Color {
        guard deltaPercent != nil else { return .secondary }
        return deltaIsGood ? .statusGood : .statusBad
    }

    private var formattedToday: String {
        guard let v = todayValue else { return "\u{2014}" }
        return String(format: measure.formatString, v)
    }

    private var formattedBaseline: String {
        guard let v = baselineValue else { return "\u{2014}" }
        return String(format: measure.formatString, v)
    }

    private var formattedLast: String {
        guard let v = lastValue else { return "\u{2014}" }
        return String(format: measure.formatString, v)
    }

    private var formattedDelta: String {
        guard let d = deltaPercent else { return "" }
        let sign = d >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", d))%"
    }

    /// The text to show when there is no data for this measure.
    private var noDataText: String {
        if measure.type == .healthKit && healthKitAuthRequested && !hasHistory {
            return "No data available \u{2014} updates automatically with Apple Watch"
        }
        return measure.promptText
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: measure.icon)
                .font(.title3)
                .foregroundStyle(state == .noData ? .secondary : Color.wellnessTeal)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(measure.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(state == .noData ? .secondary : .primary)

                switch state {
                case .noData:
                    Text(noDataText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                case .hasToday:
                    HStack(spacing: AppSpacing.sm) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(formattedToday)
                                .font(.body.weight(.medium).monospacedDigit())
                            Text(measure.unit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if baselineValue != nil {
                            Text("vs \(formattedBaseline)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !formattedDelta.isEmpty {
                            Text(formattedDelta)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(deltaColor)
                        }
                    }

                case .stale:
                    HStack(spacing: AppSpacing.sm) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(formattedLast)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(measure.unit)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let lastDate {
                            Text(lastDate.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Text("Update")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.wellnessTeal)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AppSpacing.md)
        .background(state == .noData ? Color.cardBackground.opacity(0.6) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(state == .noData ? 0.03 : 0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview("No Data") {
    MeasureCard(
        measure: .hrvSDNN,
        todayValue: nil,
        baselineValue: nil,
        lastValue: nil,
        lastDate: nil,
        hasHistory: false
    )
    .padding()
}

#Preview("No Data - HealthKit Authorized") {
    MeasureCard(
        measure: .hrvSDNN,
        todayValue: nil,
        baselineValue: nil,
        lastValue: nil,
        lastDate: nil,
        hasHistory: false,
        healthKitAuthRequested: true
    )
    .padding()
}

#Preview("Has Today") {
    MeasureCard(
        measure: .hrvSDNN,
        todayValue: 45,
        baselineValue: 40,
        lastValue: 45,
        lastDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        hasHistory: true
    )
    .padding()
}

#Preview("Stale") {
    MeasureCard(
        measure: .reactionTime,
        todayValue: nil,
        baselineValue: 320,
        lastValue: 310,
        lastDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        hasHistory: true
    )
    .padding()
}

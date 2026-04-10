import SwiftUI

/// A prominent card showing a composite recovery recommendation at the top of HomePage.
struct RecoveryRecommendationCard: View {
    let result: RecoveryScoreEngine.Result
    let baselineDayCount: Int
    let todayCompletedCount: Int

    @State private var ringAnimation: CGFloat = 0

    private var isBaseline: Bool {
        result.status == .neutral
    }

    private var statusIcon: String {
        switch result.status {
        case .good:            return "checkmark.circle.fill"
        case .moderate:        return "figure.walk"
        case .needsAttention:  return "bed.double.fill"
        case .neutral:         return "chart.line.uptrend.xyaxis"
        }
    }


    /// Day-aware warm messaging during baseline period.
    /// baselineDayCount is the number of past days with data (excluding today).
    /// So dayCount 0 = user's first day, dayCount 6 = day 7, etc.
    private var baselineWarmMessage: String? {
        guard isBaseline else { return nil }
        let userDay = baselineDayCount + 1 // Convert from 0-indexed past days to 1-indexed user day
        switch userDay {
        case 1...2:
            return String(localized: "baseline.warm.day1_2")
        case 3...4:
            return String(localized: "baseline.warm.day3_4")
        case 5...6:
            return String(localized: "baseline.warm.day5_6")
        case 7:
            return String(localized: "baseline.warm.day7")
        default:
            return nil
        }
    }

    /// Whether this is the day-7 celebration moment.
    private var isBaselineCelebration: Bool {
        isBaseline && baselineDayCount + 1 >= 7
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                // Score ring (or baseline progress ring)
                scoreRing
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.headline)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isBaseline ? .primary : result.status.color)

                    Text(result.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if isBaseline {
                        if todayCompletedCount >= Measure.allCases.count {
                            Text(String(localized: "recoveryCard.allComplete \(baselineDayCount + 1)"))
                                .font(.caption)
                                .foregroundStyle(Color.wellnessTeal)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(String(localized: "recoveryCard.progress \(todayCompletedCount) \(Measure.allCases.count)"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            // Warm coaching message during baseline period
            if isBaseline, let warmMessage = baselineWarmMessage {
                HStack(spacing: 8) {
                    if isBaselineCelebration {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.wellnessTeal)
                    }
                    Text(warmMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isBaselineCelebration ? Color.wellnessTeal : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }

            if !isBaseline {
                // Dimension count footnote
                Text(String(localized: "recoveryCard.dimensions \(result.availableDimensions) \(result.totalDimensions)"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.md + 4)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: (isBaseline ? Color.secondary : result.status.color).opacity(0.15),
                radius: 12, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                ringAnimation = 1
            }
        }
    }

    // MARK: - Score Ring

    @ViewBuilder
    private var scoreRing: some View {
        let progress = isBaseline
            ? Double(baselineDayCount) / 7.0
            : min(result.score / 100.0, 1.2)

        let ringColor = isBaseline ? Color.wellnessTeal : result.status.color

        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 6)

            Circle()
                .trim(from: 0, to: ringAnimation * min(progress, 1.0))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if isBaseline {
                Image(systemName: statusIcon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ringColor)
            } else {
                Text("\(Int(result.score))")
                    .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(ringColor)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some ShapeStyle {
        let baseColor = isBaseline ? Color.wellnessTeal : result.status.color
        return LinearGradient(
            colors: [
                baseColor.opacity(0.08),
                Color.cardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Good") {
    RecoveryRecommendationCard(
        result: .init(score: 95, status: .good,
                      headline: String(localized: "recovery.good.headline"),
                      detail: String(localized: "recovery.good.detail"),
                      availableDimensions: 7, totalDimensions: 9),
        baselineDayCount: 7,
        todayCompletedCount: 9
    )
    .padding()
}

#Preview("Building Baseline") {
    RecoveryRecommendationCard(
        result: .init(score: 0, status: .neutral,
                      headline: "Building your profile",
                      detail: "Day 3 of 7 — keep checking in daily",
                      availableDimensions: 0, totalDimensions: 9),
        baselineDayCount: 3,
        todayCompletedCount: 4
    )
    .padding()
}

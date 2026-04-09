import SwiftUI

/// A prominent card showing a composite recovery recommendation at the top of HomePage.
struct RecoveryRecommendationCard: View {
    let result: RecoveryScoreEngine.Result
    let baselineDayCount: Int

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
                }

                Spacer(minLength: 0)
            }

            if !isBaseline {
                // Dimension count footnote
                Text("Based on \(result.availableDimensions) of \(result.totalDimensions) dimensions")
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
                      headline: "Ready to train",
                      detail: "Your metrics are at or above baseline — go for it",
                      availableDimensions: 7, totalDimensions: 9),
        baselineDayCount: 7
    )
    .padding()
}

#Preview("Moderate") {
    RecoveryRecommendationCard(
        result: .init(score: 78, status: .moderate,
                      headline: "Light activity today",
                      detail: "Some metrics are below your norm — keep it easy",
                      availableDimensions: 5, totalDimensions: 9),
        baselineDayCount: 7
    )
    .padding()
}

#Preview("Needs Attention") {
    RecoveryRecommendationCard(
        result: .init(score: 55, status: .needsAttention,
                      headline: "Rest and recover",
                      detail: "Multiple metrics suggest fatigue — prioritize recovery",
                      availableDimensions: 9, totalDimensions: 9),
        baselineDayCount: 7
    )
    .padding()
}

#Preview("Building Baseline") {
    RecoveryRecommendationCard(
        result: .init(score: 0, status: .neutral,
                      headline: "Building your profile",
                      detail: "Day 3 of 7 — keep checking in daily",
                      availableDimensions: 0, totalDimensions: 9),
        baselineDayCount: 3
    )
    .padding()
}

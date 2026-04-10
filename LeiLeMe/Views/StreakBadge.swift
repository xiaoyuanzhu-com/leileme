import SwiftUI

/// A compact streak display that sits below the recovery card on the Home page.
struct StreakBadge: View {
    let streakCount: Int
    let milestoneMessage: String?
    let graceUsed: Bool

    var body: some View {
        if streakCount > 0 {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(flameColor)

                Text(String(localized: "streak.dayCount \(streakCount)"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if graceUsed {
                    Text(String(localized: "streak.graceUsed"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let milestone = milestoneMessage {
                    Text(milestone)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(flameColor)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(flameColor.opacity(0.08))
            )
        }
    }

    private var flameColor: Color {
        if streakCount >= 30 {
            return .wellnessRed
        } else if streakCount >= 14 {
            return Color(light: .init(red: 0.85, green: 0.45, blue: 0.15),
                         dark: .init(red: 0.95, green: 0.55, blue: 0.25))
        } else if streakCount >= 7 {
            return .wellnessAmber
        } else {
            return .wellnessTeal
        }
    }
}

#Preview("Short streak") {
    StreakBadge(streakCount: 2, milestoneMessage: nil, graceUsed: false)
        .padding()
}

#Preview("Milestone") {
    StreakBadge(streakCount: 7, milestoneMessage: String(localized: "streak.milestone.7"), graceUsed: false)
        .padding()
}

#Preview("Grace used") {
    StreakBadge(streakCount: 5, milestoneMessage: nil, graceUsed: true)
        .padding()
}

#Preview("30-day") {
    StreakBadge(streakCount: 30, milestoneMessage: String(localized: "streak.milestone.30"), graceUsed: false)
        .padding()
}

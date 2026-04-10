import SwiftUI

/// A tasteful overlay celebration shown when all 9 measures are completed for today.
/// Appears once per day, dismisses on tap or after 3 seconds.
/// Non-blocking — allows pass-through interaction.
struct CompletionCelebrationView: View {
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var glowPhase: CGFloat = 0
    @State private var particleOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var particleOffsets: [CGSize] = Array(repeating: .zero, count: 8)

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Checkmark with glow
            ZStack {
                // Glow ring
                Circle()
                    .stroke(Color.wellnessGreen.opacity(0.3 * glowPhase), lineWidth: 3)
                    .frame(width: 44, height: 44)
                    .scaleEffect(1.0 + 0.15 * glowPhase)

                // Particles (subtle dots radiating outward)
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(particleColor(for: i))
                        .frame(width: 4, height: 4)
                        .opacity(particleOpacities[i])
                        .offset(particleOffsets[i])
                }

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.wellnessGreen)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
            }

            Text(String(localized: "celebration.title"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(String(localized: "celebration.subtitle"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.wellnessGreen.opacity(0.15), radius: 16, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onTapGesture {
            dismissWithAnimation()
        }
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.3)) {
                glowPhase = 1.0
            }

            // Particle animation
            animateParticles()

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissWithAnimation()
            }
        }
        .allowsHitTesting(true) // Only the overlay itself captures taps
    }

    // MARK: - Particles

    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.wellnessGreen, .wellnessTeal, .wellnessBlue, .wellnessGreen]
        return colors[index % colors.count]
    }

    private func animateParticles() {
        for i in 0..<8 {
            let angle = Double(i) * (.pi / 4.0)
            let distance: CGFloat = CGFloat.random(in: 24...40)

            // Stagger particle appearance
            let delay = 0.3 + Double(i) * 0.05

            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                particleOpacities[i] = 0.7
                particleOffsets[i] = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
            }

            // Fade out particles
            withAnimation(.easeIn(duration: 0.4).delay(delay + 0.6)) {
                particleOpacities[i] = 0
            }
        }
    }

    // MARK: - Dismiss

    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - UserDefaults tracking for once-per-day display

enum CelebrationTracker {
    private static let lastCelebrationDateKey = "completion_celebration_last_date"

    /// Whether the celebration has already been shown today.
    static var hasShownToday: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: lastCelebrationDateKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// Mark the celebration as shown today.
    static func markShown() {
        UserDefaults.standard.set(Date(), forKey: lastCelebrationDateKey)
    }
}

#Preview {
    ZStack {
        Color.surfaceBackground.ignoresSafeArea()
        CompletionCelebrationView(onDismiss: {})
    }
}

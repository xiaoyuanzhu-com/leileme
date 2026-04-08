import SwiftUI

// MARK: - Color Palette

extension Color {
    // Adaptive colors with light/dark support
    static let wellnessTeal = Color(light: .init(red: 0.29, green: 0.56, blue: 0.62),
                                     dark: .init(red: 0.40, green: 0.72, blue: 0.78))
    static let wellnessBlue = Color(light: .init(red: 0.25, green: 0.47, blue: 0.65),
                                     dark: .init(red: 0.38, green: 0.62, blue: 0.82))
    static let wellnessGreen = Color(light: .init(red: 0.30, green: 0.60, blue: 0.40),
                                      dark: .init(red: 0.42, green: 0.75, blue: 0.52))
    static let wellnessAmber = Color(light: .init(red: 0.80, green: 0.60, blue: 0.20),
                                      dark: .init(red: 0.90, green: 0.72, blue: 0.35))
    static let wellnessRed = Color(light: .init(red: 0.78, green: 0.30, blue: 0.28),
                                    dark: .init(red: 0.90, green: 0.42, blue: 0.40))

    // Backgrounds
    static let surfaceBackground = Color(light: .init(red: 0.96, green: 0.97, blue: 0.98),
                                          dark: .init(red: 0.11, green: 0.11, blue: 0.12))
    static let cardBackground = Color(light: .white,
                                       dark: .init(red: 0.17, green: 0.17, blue: 0.18))
    static let cardBackgroundElevated = Color(light: .init(red: 0.98, green: 0.98, blue: 1.0),
                                               dark: .init(red: 0.21, green: 0.21, blue: 0.22))

    // Status colors
    static let statusGood = wellnessGreen
    static let statusWarning = wellnessAmber
    static let statusBad = wellnessRed
    static let statusNeutral = Color.secondary

    // Convenience init for adaptive light/dark
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Spacing Constants

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(Color.cardBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func elevatedCardStyle() -> some View {
        modifier(ElevatedCardStyle())
    }
}

// MARK: - Gradient Backgrounds

extension LinearGradient {
    static let wellnessBackground = LinearGradient(
        colors: [
            Color.wellnessTeal.opacity(0.08),
            Color.surfaceBackground,
            Color.wellnessBlue.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let assessmentBackground = LinearGradient(
        colors: [
            Color.wellnessTeal.opacity(0.12),
            Color.surfaceBackground
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .wellnessTeal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Color.wellnessTeal)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.wellnessTeal.opacity(0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Section Header Style

struct ThemedSectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .wellnessTeal

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }
}

// MARK: - Status Helpers

enum RecoveryStatus {
    case good, moderate, needsAttention, neutral

    var color: Color {
        switch self {
        case .good: return .statusGood
        case .moderate: return .statusWarning
        case .needsAttention: return .statusBad
        case .neutral: return .statusNeutral
        }
    }

    var label: String {
        switch self {
        case .good: return "Good"
        case .moderate: return "Fair"
        case .needsAttention: return "Low"
        case .neutral: return "\u{2014}"
        }
    }
}

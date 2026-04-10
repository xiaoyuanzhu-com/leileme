import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false

    @State private var showNotificationOnboarding = false

    var body: some View {
        HomePage()
            .onAppear {
                if !hasCompletedOnboarding {
                    // Show notification permission request on first launch
                    if let nm = notificationManager, !nm.hasRequestedPermission {
                        showNotificationOnboarding = true
                    } else {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .sheet(isPresented: $showNotificationOnboarding) {
                NotificationOnboardingView {
                    hasCompletedOnboarding = true
                    showNotificationOnboarding = false
                }
            }
    }
}

// MARK: - Notification Onboarding View

struct NotificationOnboardingView: View {
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.wellnessTeal)
                .symbolRenderingMode(.hierarchical)

            Text("Stay on Track")
                .font(.title.bold())

            Text("A gentle morning reminder helps you build a daily check-in habit. Your baseline gets more accurate with each day of data.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                featureRow(icon: "clock.fill", text: "Daily reminder at 7:30 AM")
                featureRow(icon: "gearshape.fill", text: "Change time or disable anytime in Settings")
                featureRow(icon: "moon.fill", text: "Respects Do Not Disturb")
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button {
                    Task {
                        await notificationManager?.requestAuthorization()
                        onComplete()
                    }
                } label: {
                    Text("Enable Reminders")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    onComplete()
                } label: {
                    Text("Not Now")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(Color.surfaceBackground)
        .interactiveDismissDisabled()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.wellnessTeal)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environment(HealthKitService())
        .environment(NotificationManager())
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

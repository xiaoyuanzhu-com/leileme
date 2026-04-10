import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @Environment(HealthKitService.self) private var healthKitService: HealthKitService?
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false

    @State private var showOnboarding = false

    var body: some View {
        HomePage()
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
            }
    }
}

// MARK: - Onboarding Flow View

/// Multi-step onboarding: notifications → HealthKit authorization.
struct OnboardingFlowView: View {
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @Environment(HealthKitService.self) private var healthKitService: HealthKitService?
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?

    enum Step {
        case notifications
        case healthKit
    }

    @State private var currentStep: Step = .notifications
    var onComplete: () -> Void

    var body: some View {
        Group {
            switch currentStep {
            case .notifications:
                NotificationOnboardingView {
                    // After notification step, move to HealthKit step
                    withAnimation {
                        currentStep = .healthKit
                    }
                }
            case .healthKit:
                HealthKitOnboardingView {
                    onComplete()
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
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

// MARK: - HealthKit Onboarding View

struct HealthKitOnboardingView: View {
    @Environment(HealthKitService.self) private var healthKitService: HealthKitService?
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.wellnessTeal)
                .symbolRenderingMode(.hierarchical)

            Text("Connect Apple Health")
                .font(.title.bold())

            Text("We read heart rate, HRV, and sleep data from Apple Health to assess your recovery.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                featureRow(icon: "waveform.path.ecg", text: "Heart rate variability (HRV)")
                featureRow(icon: "heart.fill", text: "Resting heart rate")
                featureRow(icon: "bed.double.fill", text: "Sleep duration & stages")
                featureRow(icon: "lock.shield.fill", text: "Read-only — we never write to Health")
            }
            .padding(.horizontal, AppSpacing.lg)

            if let healthKitService, !healthKitService.isAvailable {
                Text("Apple Health is not available on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button {
                    Task {
                        await authorizeAndSync()
                        onComplete()
                    }
                } label: {
                    Text("Allow Health Access")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(healthKitService?.isAvailable != true)

                Button {
                    healthKitService?.markAuthorizationRequested()
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

    private func authorizeAndSync() async {
        guard let healthKitService else { return }
        do {
            try await healthKitService.requestAuthorization()
            // Immediately sync after authorization
            if let assessmentStore {
                let reading = try await healthKitService.fetchCurrentReading()
                assessmentStore.saveHealthKitReading(reading)
            }
        } catch {
            // Auth failed or sync failed — still mark as requested so we don't re-prompt
        }
        healthKitService.markAuthorizationRequested()
    }
}

#Preview {
    ContentView()
        .environment(HealthKitService())
        .environment(NotificationManager())
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

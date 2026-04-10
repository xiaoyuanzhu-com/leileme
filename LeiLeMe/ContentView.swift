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

/// Multi-step onboarding: notifications -> HealthKit authorization.
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

            Text(String(localized: "onboarding.notifications.title"))
                .font(.title.bold())

            Text(String(localized: "onboarding.notifications.body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                featureRow(icon: "clock.fill", text: String(localized: "onboarding.notifications.dailyAt"))
                featureRow(icon: "gearshape.fill", text: String(localized: "onboarding.notifications.changeAnytime"))
                featureRow(icon: "moon.fill", text: String(localized: "onboarding.notifications.dnd"))
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
                    Text(String(localized: "onboarding.notifications.enable"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    onComplete()
                } label: {
                    Text(String(localized: "onboarding.notifications.notNow"))
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

            Text(String(localized: "onboarding.healthKit.title"))
                .font(.title.bold())

            Text(String(localized: "onboarding.healthKit.body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                featureRow(icon: "waveform.path.ecg", text: String(localized: "onboarding.healthKit.hrv"))
                featureRow(icon: "heart.fill", text: String(localized: "onboarding.healthKit.rhr"))
                featureRow(icon: "bed.double.fill", text: String(localized: "onboarding.healthKit.sleep"))
                featureRow(icon: "lock.shield.fill", text: String(localized: "onboarding.healthKit.readOnly"))
            }
            .padding(.horizontal, AppSpacing.lg)

            if let healthKitService, !healthKitService.isAvailable {
                Text(String(localized: "onboarding.healthKit.notAvailable"))
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
                    Text(String(localized: "onboarding.healthKit.allow"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(healthKitService?.isAvailable != true)

                Button {
                    healthKitService?.markAuthorizationRequested()
                    onComplete()
                } label: {
                    Text(String(localized: "onboarding.healthKit.notNow"))
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

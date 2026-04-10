import SwiftUI
import SwiftData

struct SettingsTab: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]

    @State private var showResetBaselineConfirmation = false
    @State private var showClearDataConfirmation = false

    private var baseline: BaselineEngine.BaselineSnapshot {
        BaselineEngine().computeBaseline(from: assessments)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "\u{2014}"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "\u{2014}"
        return "\(version) (\(build))"
    }

    var body: some View {
        Group {
            Form {
                notificationSection
                baselineSection
                healthKitSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBackground)
            .navigationTitle("Settings")
        }
    }

    // MARK: - Notification Section

    @ViewBuilder
    private var notificationSection: some View {
        if let nm = notificationManager {
            Section {
                @Bindable var nmBindable = nm

                Toggle(isOn: $nmBindable.remindersEnabled) {
                    Label("Daily Reminder", systemImage: "bell.fill")
                }
                .tint(Color.wellnessTeal)

                if nm.remindersEnabled {
                    DatePicker(
                        selection: $nmBindable.reminderTime,
                        displayedComponents: .hourAndMinute
                    ) {
                        Label("Reminder Time", systemImage: "clock")
                    }
                }

                // Authorization status
                HStack {
                    Label("Notifications", systemImage: "app.badge")
                    Spacer()
                    Group {
                        switch nm.authorizationStatus {
                        case .authorized:
                            Text("Allowed")
                                .foregroundStyle(Color.wellnessGreen)
                        case .denied:
                            Text("Denied")
                                .foregroundStyle(Color.wellnessRed)
                        case .provisional:
                            Text("Provisional")
                                .foregroundStyle(Color.wellnessAmber)
                        default:
                            Text("Not Requested")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }

                if nm.authorizationStatus == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open System Settings", systemImage: "gear")
                    }
                }

                if !nm.isAuthorized && nm.authorizationStatus != .denied {
                    Button {
                        Task {
                            await nm.requestAuthorization()
                        }
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                if nm.remindersEnabled && nm.isAuthorized {
                    Text("You'll receive a daily reminder at \(nm.formattedReminderTime).")
                } else if nm.authorizationStatus == .denied {
                    Text("Notifications are disabled in System Settings. Tap above to change.")
                } else {
                    Text("Get a gentle daily nudge to check in on your recovery.")
                }
            }
        }
    }

    // MARK: - Baseline Section

    private var baselineSection: some View {
        Section {
            HStack {
                Label("Data collected", systemImage: "calendar")
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(baseline.dayCount) day\(baseline.dayCount == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
            }

            if baseline.dayCount >= 7 {
                Label("Baseline ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.wellnessGreen)
            } else if baseline.dayCount > 0 {
                Label("\(7 - baseline.dayCount) more day\(7 - baseline.dayCount == 1 ? "" : "s") needed", systemImage: "clock")
                    .foregroundStyle(Color.wellnessAmber)
            } else {
                Label("No data yet", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showResetBaselineConfirmation = true
            } label: {
                Label("Reset Baseline", systemImage: "arrow.counterclockwise")
            }
            .disabled(assessments.isEmpty)
            .confirmationDialog(
                "Reset Baseline",
                isPresented: $showResetBaselineConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Baseline", role: .destructive) {
                    resetBaseline()
                }
            } message: {
                Text("This will delete assessments older than today. Your baseline will be recalculated from new data.")
            }
        } header: {
            Text("Baseline")
        } footer: {
            Text("A 7-day rolling window is used to compute your baseline.")
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        Section {
            HStack {
                Label("Authorization", systemImage: "lock.shield")
                Spacer()
                Text(healthKitService.isAuthorized ? "Granted" : "Not Requested")
                    .foregroundStyle(healthKitService.isAuthorized ? Color.wellnessGreen : .secondary)
            }

            if healthKitService.isAvailable {
                healthKitTypeRow("HRV (SDNN)", systemImage: "waveform.path.ecg")
                healthKitTypeRow("Resting Heart Rate", systemImage: "heart.fill")
                healthKitTypeRow("Sleep Analysis", systemImage: "bed.double.fill")

                Button {
                    openHealthApp()
                } label: {
                    Label("Open Health Settings", systemImage: "heart.circle")
                }
            } else {
                Label("HealthKit not available", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("HealthKit")
        } footer: {
            Text("Authorization is managed in the Health app. Tap \"Open Health Settings\" to review permissions.")
        }
    }

    private func healthKitTypeRow(_ name: String, systemImage: String) -> some View {
        HStack {
            Label(name, systemImage: systemImage)
            Spacer()
            Image(systemName: healthKitService.isAuthorized ? "checkmark.circle.fill" : "questionmark.circle")
                .foregroundStyle(healthKitService.isAuthorized ? Color.wellnessGreen : .secondary)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            HStack {
                Label("Total assessments", systemImage: "number")
                Spacer()
                Text("\(assessments.count)")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showClearDataConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
            .disabled(assessments.isEmpty)
            .confirmationDialog(
                "Clear All Data",
                isPresented: $showClearDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Assessments", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all \(assessments.count) assessment\(assessments.count == 1 ? "" : "s"). This cannot be undone.")
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Label("App", systemImage: "app.badge")
                Spacer()
                Text("LeiLeMe (\u{7D2F}\u{4E86}\u{4E48})")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Text("A daily fatigue check-in combining HealthKit biometrics, motor tests, and subjective ratings to track recovery trends.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://github.com/iloahz/LeiLeMe")!) {
                Label("View on GitHub", systemImage: "link")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Actions

    private func resetBaseline() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let toDelete = assessments.filter { $0.date < startOfToday }
        for assessment in toDelete {
            modelContext.delete(assessment)
        }
    }

    private func clearAllData() {
        for assessment in assessments {
            modelContext.delete(assessment)
        }
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsTab()
        .environment(HealthKitService())
        .environment(NotificationManager())
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

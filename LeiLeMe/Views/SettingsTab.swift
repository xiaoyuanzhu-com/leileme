import SwiftUI
import SwiftData

struct SettingsTab: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(NotificationManager.self) private var notificationManager: NotificationManager?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyAssessment.date, order: .reverse) private var assessments: [DailyAssessment]

    @State private var showRecalibrateConfirmation = false
    @State private var showClearDataConfirmation = false
    @State private var showRecalibrateExplanation = false
    @State private var dominantHand: Hand = UserSettings.dominantHand
    @State private var exportFormat: DataExporter.ExportFormat = .csv
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var showNoDataAlert = false

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
                gripStrengthSection
                exportSection
                recalibrateSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBackground)
            .navigationTitle(String(localized: "settings.title"))
        }
    }

    // MARK: - Notification Section

    @ViewBuilder
    private var notificationSection: some View {
        if let nm = notificationManager {
            Section {
                @Bindable var nmBindable = nm

                Toggle(isOn: $nmBindable.remindersEnabled) {
                    Label(String(localized: "settings.dailyReminder"), systemImage: "bell.fill")
                }
                .tint(Color.wellnessTeal)

                if nm.remindersEnabled {
                    DatePicker(
                        selection: $nmBindable.reminderTime,
                        displayedComponents: .hourAndMinute
                    ) {
                        Label(String(localized: "settings.reminderTime"), systemImage: "clock")
                    }
                }

                // Authorization status
                HStack {
                    Label(String(localized: "settings.notifications"), systemImage: "app.badge")
                    Spacer()
                    Group {
                        switch nm.authorizationStatus {
                        case .authorized:
                            Text(String(localized: "settings.notifications.allowed"))
                                .foregroundStyle(Color.wellnessGreen)
                        case .denied:
                            Text(String(localized: "settings.notifications.denied"))
                                .foregroundStyle(Color.wellnessRed)
                        case .provisional:
                            Text(String(localized: "settings.notifications.provisional"))
                                .foregroundStyle(Color.wellnessAmber)
                        default:
                            Text(String(localized: "settings.notifications.notRequested"))
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
                        Label(String(localized: "settings.openSystemSettings"), systemImage: "gear")
                    }
                }

                if !nm.isAuthorized && nm.authorizationStatus != .denied {
                    Button {
                        Task {
                            await nm.requestAuthorization()
                        }
                    } label: {
                        Label(String(localized: "settings.enableNotifications"), systemImage: "bell.badge")
                    }
                }
            } header: {
                Text(String(localized: "settings.reminders"))
            } footer: {
                if nm.remindersEnabled && nm.isAuthorized {
                    Text(String(localized: "settings.reminders.footer.enabled \(nm.formattedReminderTime)"))
                } else if nm.authorizationStatus == .denied {
                    Text(String(localized: "settings.reminders.footer.denied"))
                } else {
                    Text(String(localized: "settings.reminders.footer.default"))
                }
            }
        }
    }

    // MARK: - Baseline Section

    private var baselineSection: some View {
        Section {
            HStack {
                Label(String(localized: "settings.dataCollected"), systemImage: "calendar")
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(localized: "settings.days \(baseline.dayCount)"))
                    .foregroundStyle(.secondary)
            }

            if baseline.dayCount >= 7 {
                Label(String(localized: "settings.baselineReady"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.wellnessGreen)
            } else if baseline.dayCount > 0 {
                Label(String(localized: "settings.daysNeeded \(7 - baseline.dayCount)"), systemImage: "clock")
                    .foregroundStyle(Color.wellnessAmber)
            } else {
                Label(String(localized: "settings.noDataYet"), systemImage: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "settings.baseline"))
        } footer: {
            Text(String(localized: "settings.baseline.footer"))
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        Section {
            HStack {
                Label(String(localized: "settings.authorization"), systemImage: "lock.shield")
                Spacer()
                Text(healthKitService.isAuthorized
                     ? String(localized: "settings.authorization.granted")
                     : String(localized: "settings.authorization.notRequested"))
                    .foregroundStyle(healthKitService.isAuthorized ? Color.wellnessGreen : .secondary)
            }

            if healthKitService.isAvailable {
                healthKitTypeRow(String(localized: "settings.healthKit.hrvSDNN"), systemImage: "waveform.path.ecg")
                healthKitTypeRow(String(localized: "settings.healthKit.restingHeartRate"), systemImage: "heart.fill")
                healthKitTypeRow(String(localized: "settings.healthKit.sleepAnalysis"), systemImage: "bed.double.fill")

                Button {
                    openHealthApp()
                } label: {
                    Label(String(localized: "settings.openHealthSettings"), systemImage: "heart.circle")
                }
            } else {
                Label(String(localized: "settings.healthKit.notAvailable"), systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "settings.healthKit"))
        } footer: {
            Text(String(localized: "settings.healthKit.footer"))
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
                Label(String(localized: "settings.totalAssessments"), systemImage: "number")
                Spacer()
                Text("\(assessments.count)")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showClearDataConfirmation = true
            } label: {
                Label(String(localized: "settings.clearAllData"), systemImage: "trash")
            }
            .disabled(assessments.isEmpty)
            .confirmationDialog(
                String(localized: "settings.clearAllData.title"),
                isPresented: $showClearDataConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.clearAllData.button"), role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text(String(localized: "settings.clearAllData.message \(assessments.count)"))
            }
        } header: {
            Text(String(localized: "settings.data"))
        }
    }

    // MARK: - Grip Strength Section

    private var gripStrengthSection: some View {
        Section {
            Picker(String(localized: "settings.gripStrength.dominantHand.title"), selection: $dominantHand) {
                Text(String(localized: "settings.gripStrength.dominantHand.left")).tag(Hand.left)
                Text(String(localized: "settings.gripStrength.dominantHand.right")).tag(Hand.right)
            }
            .pickerStyle(.segmented)
            .onChange(of: dominantHand) { _, newValue in
                UserSettings.dominantHand = newValue
            }
        } header: {
            Text(String(localized: "settings.gripStrength.section"))
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Picker(String(localized: "settings.export.format"), selection: $exportFormat) {
                ForEach(DataExporter.ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)

            Button {
                exportData()
            } label: {
                Label(String(localized: "settings.exportAllData"), systemImage: "square.and.arrow.up")
            }
            .disabled(assessments.isEmpty)
        } header: {
            Text(String(localized: "settings.export"))
        } footer: {
            Text(assessments.isEmpty
                 ? String(localized: "settings.export.noData")
                 : String(localized: "settings.export.footer \(assessments.count) \(exportFormat.rawValue)"))
        }
        .alert(String(localized: "settings.export.noDataAlert.title"), isPresented: $showNoDataAlert) {
            Button(String(localized: "settings.export.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.export.noDataAlert.message"))
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

        // MARK: - Recalibrate Section

    private var recalibrateSection: some View {
        Section {
            Button {
                showRecalibrateConfirmation = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label(String(localized: "settings.recalibrateBaseline"), systemImage: "arrow.triangle.2.circlepath")
                    Text(String(localized: "settings.recalibrate.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(assessments.isEmpty)
            .alert(
                String(localized: "settings.recalibrate.title"),
                isPresented: $showRecalibrateConfirmation
            ) {
                Button(String(localized: "settings.recalibrate.continue")) {
                    recalibrateBaseline()
                }
                Button(String(localized: "settings.recalibrate.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings.recalibrate.message"))
            }

            DisclosureGroup(String(localized: "settings.whyRecalibrate"), isExpanded: $showRecalibrateExplanation) {
                Text(String(localized: "settings.recalibrate.explanation"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } header: {
            Text(String(localized: "settings.recalibrate"))
        } footer: {
            Text(String(localized: "settings.recalibrate.footer"))
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Label(String(localized: "settings.about.app"), systemImage: "app.badge")
                Spacer()
                Text(String(localized: "settings.about.appName"))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(String(localized: "settings.about.version"), systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Text(String(localized: "app.tagline"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://github.com/iloahz/LeiLeMe")!) {
                Label(String(localized: "settings.viewOnGitHub"), systemImage: "link")
            }
        } header: {
            Text(String(localized: "settings.about"))
        }
    }

    // MARK: - Actions

    private func recalibrateBaseline() {
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
    private func exportData() {
        guard !assessments.isEmpty else {
            showNoDataAlert = true
            return
        }

        guard let url = DataExporter.export(
            assessments: assessments,
            format: exportFormat,
            baseline: baseline
        ) else { return }

        exportFileURL = url
        showExportSheet = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsTab()
        .environment(HealthKitService())
        .environment(NotificationManager())
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

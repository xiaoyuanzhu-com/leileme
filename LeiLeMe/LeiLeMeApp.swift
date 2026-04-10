import SwiftUI
import SwiftData

@main
struct LeiLeMeApp: App {
    @State private var healthKitService = HealthKitService()
    @State private var assessmentStore: AssessmentStore?
    @State private var notificationManager = NotificationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyAssessment.self,
            HealthKitReading.self,
            TapTestResult.self,
            ReactionTimeResult.self,
            SubjectiveAssessment.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitService)
                .environment(notificationManager)
                .task {
                    if assessmentStore == nil {
                        assessmentStore = AssessmentStore(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                    // Refresh notification authorization status on launch
                    await notificationManager.refreshAuthorizationStatus()
                    // Re-schedule notifications if enabled (keeps rotation fresh)
                    if notificationManager.remindersEnabled && notificationManager.isAuthorized {
                        notificationManager.scheduleNotifications()
                    }
                }
                .environment(assessmentStore)
                .tint(.wellnessTeal)
        }
        .modelContainer(sharedModelContainer)
    }
}

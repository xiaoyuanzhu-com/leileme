import SwiftUI
import SwiftData

@main
struct LeiLeMeApp: App {
    @State private var healthKitService = HealthKitService()
    @State private var assessmentStore: AssessmentStore?

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
                .task {
                    if assessmentStore == nil {
                        assessmentStore = AssessmentStore(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                }
                .environment(assessmentStore)
                .tint(.wellnessTeal)
        }
        .modelContainer(sharedModelContainer)
    }
}

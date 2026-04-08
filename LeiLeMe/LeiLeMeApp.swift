import SwiftUI
import SwiftData

@main
struct LeiLeMeApp: App {
    @State private var healthKitService = HealthKitService()

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
        }
        .modelContainer(sharedModelContainer)
    }
}

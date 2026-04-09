import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomePage()
    }
}

#Preview {
    ContentView()
        .environment(HealthKitService())
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}

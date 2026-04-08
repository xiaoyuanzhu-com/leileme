import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AssessmentTab()
                .tabItem {
                    Label("Assess", systemImage: "heart.text.square")
                }

            HistoryTab()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.wellnessTeal)
    }
}

#Preview {
    ContentView()
}

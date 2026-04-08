import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AssessmentTab()
                .tabItem {
                    Label("Assessment", systemImage: "heart.text.clipboard")
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
    }
}

#Preview {
    ContentView()
}

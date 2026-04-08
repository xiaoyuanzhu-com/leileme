import SwiftUI

struct SettingsTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Settings")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTab()
}

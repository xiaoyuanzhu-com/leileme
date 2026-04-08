import SwiftUI

struct HistoryTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("History")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryTab()
}

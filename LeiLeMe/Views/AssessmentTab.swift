import SwiftUI

struct AssessmentTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Assessment")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Assessment")
        }
    }
}

#Preview {
    AssessmentTab()
}

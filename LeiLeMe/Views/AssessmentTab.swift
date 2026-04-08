import SwiftUI
import SwiftData

struct AssessmentTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showTapTest = false

    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    Button {
                        showTapTest = true
                    } label: {
                        Label("Tap Test", systemImage: "hand.tap.fill")
                    }
                }
            }
            .navigationTitle("Assessment")
            .fullScreenCover(isPresented: $showTapTest) {
                TapTestView { result in
                    modelContext.insert(result)
                    showTapTest = false
                }
            }
        }
    }
}

#Preview {
    AssessmentTab()
        .modelContainer(for: TapTestResult.self, inMemory: true)
}

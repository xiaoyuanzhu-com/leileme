import SwiftUI

struct GripStrengthLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AssessmentStore.self) private var assessmentStore: AssessmentStore?

    @State private var valueText: String = ""
    @State private var hand: Hand = UserSettings.dominantHand
    @State private var timestamp: Date = Date()

    private var parsedValue: Double? {
        let normalized = valueText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var canSave: Bool {
        if let v = parsedValue, v > 0 { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField(
                            String(localized: "gripStrength.add.valueLabel"),
                            text: $valueText
                        )
                        .keyboardType(.decimalPad)
                        Text(String(localized: "measure.unit.kg"))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "gripStrength.add.valueLabel"))
                }

                Section {
                    Picker(String(localized: "gripStrength.add.handLabel"), selection: $hand) {
                        Text(String(localized: "settings.gripStrength.dominantHand.left")).tag(Hand.left)
                        Text(String(localized: "settings.gripStrength.dominantHand.right")).tag(Hand.right)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(String(localized: "gripStrength.add.handLabel"))
                }

                Section {
                    DatePicker(
                        String(localized: "gripStrength.add.timeLabel"),
                        selection: $timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text(String(localized: "gripStrength.add.timeLabel"))
                }
            }
            .navigationTitle(String(localized: "gripStrength.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "gripStrength.add.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "gripStrength.add.save")) {
                        guard let value = parsedValue, value > 0 else { return }
                        assessmentStore?.addGripStrengthReading(
                            valueKg: value,
                            hand: hand,
                            timestamp: timestamp
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

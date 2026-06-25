import SwiftUI
import SwiftData

struct AddPillView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var purpose = ""
    @State private var loggedAt = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section("Which pill?") {
                    TextField("e.g. Digestion Pill", text: $name)
                }
                Section("What are you using it for?") {
                    TextField("e.g. digestion (optional)", text: $purpose)
                }
                Section("When") {
                    DatePicker("Taken at", selection: $loggedAt)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backdrop(Theme.pillsTint))
            .navigationTitle("Log Pill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(Theme.pillsTint)
    }

    private func save() {
        context.insert(PillLog(
            name: name.trimmingCharacters(in: .whitespaces),
            purpose: purpose.trimmingCharacters(in: .whitespaces),
            loggedAt: loggedAt
        ))
        dismiss()
    }
}

#Preview {
    AddPillView()
        .modelContainer(DataController.shared.container)
}

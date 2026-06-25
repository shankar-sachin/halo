import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type = ""
    @State private var duration = 30
    @State private var calories = 0
    @State private var loggedAt = Date.now

    private let suggestions = ["Run", "Walk", "Cycling", "Swim", "Yoga", "Strength", "Hike"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("e.g. Run", text: $type)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestions, id: \.self) { s in
                                Button(s) { type = s }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.workoutsTint)
                            }
                        }
                    }
                }
                Section("Details") {
                    Stepper("Duration: \(duration) min", value: $duration, in: 5...300, step: 5)
                    TextField("Calories (optional)", value: $calories, format: .number)
                        .keyboardType(.numberPad)
                    DatePicker("When", selection: $loggedAt)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backdrop(Theme.workoutsTint))
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log", action: save)
                        .disabled(type.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(Theme.workoutsTint)
    }

    private func save() {
        context.insert(Workout(
            type: type.trimmingCharacters(in: .whitespaces),
            durationMinutes: duration,
            calories: max(calories, 0),
            loggedAt: loggedAt
        ))
        dismiss()
    }
}

#Preview {
    AddWorkoutView()
        .modelContainer(DataController.shared.container)
}

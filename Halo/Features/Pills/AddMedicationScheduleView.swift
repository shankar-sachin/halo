import SwiftUI
import SwiftData

/// Creates a recurring medication reminder and schedules its daily notification.
struct AddMedicationScheduleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dose = ""
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name (e.g. Vitamin D)", text: $name)
                    TextField("Dose (optional)", text: $dose)
                }
                Section("Reminder") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(Theme.pillsTint)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)

        let schedule = MedicationSchedule(name: trimmed.capitalized, dose: dose.trimmingCharacters(in: .whitespaces), timesMinutesOfDay: [minutes])
        context.insert(schedule)
        try? context.save()

        Task {
            await NotificationService.shared.scheduleDailyReminder(
                id: schedule.reminderIDs().first ?? UUID().uuidString,
                title: "Time for \(schedule.name)",
                body: "Tap to log it in Halo.",
                hour: minutes / 60, minute: minutes % 60
            )
        }
        dismiss()
    }
}

#Preview {
    AddMedicationScheduleView()
        .modelContainer(DataController.shared.container)
}

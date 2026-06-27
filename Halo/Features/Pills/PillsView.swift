import SwiftUI
import SwiftData

struct PillsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PillLog.loggedAt, order: .reverse) private var pills: [PillLog]
    @Query(sort: \MedicationSchedule.createdAt) private var schedules: [MedicationSchedule]

    @State private var showAdd = false
    @State private var showAddSchedule = false

    private var today: [PillLog] { pills.filter { Calendar.current.isDateInToday($0.loggedAt) } }
    private var earlier: [PillLog] { pills.filter { !Calendar.current.isDateInToday($0.loggedAt) } }
    private var activeSchedules: [MedicationSchedule] { schedules.filter { $0.active } }

    var body: some View {
        NavigationStack {
            Group {
                if pills.isEmpty && schedules.isEmpty {
                    ContentUnavailableView(
                        "No pills logged",
                        systemImage: "pills.fill",
                        description: Text("Tap + or say “Halo, I ate my digestion pill.”")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if !activeSchedules.isEmpty {
                                sectionHeader("Schedule")
                                ForEach(activeSchedules) { scheduleRow($0) }
                            }
                            if !today.isEmpty {
                                sectionHeader("Today")
                                ForEach(today) { row($0) }
                            }
                            if !earlier.isEmpty {
                                sectionHeader("Earlier")
                                ForEach(earlier) { row($0) }
                            }
                        }
                        .padding()
                        .readableWidth()
                    }
                }
            }
            .background(Theme.backdrop(Theme.pillsTint))
            .navigationTitle("Pills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showAdd = true } label: { Label("Log a pill", systemImage: "pills") }
                        Button { showAddSchedule = true } label: { Label("Add a schedule", systemImage: "alarm") }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddPillView() }
            .sheet(isPresented: $showAddSchedule) { AddMedicationScheduleView() }
        }
        .tint(Theme.pillsTint)
    }

    /// Whether a pill matching the schedule's name was logged today.
    private func takenToday(_ schedule: MedicationSchedule) -> Bool {
        today.contains { $0.name.lowercased() == schedule.name.lowercased() }
    }

    private func scheduleRow(_ schedule: MedicationSchedule) -> some View {
        let taken = takenToday(schedule)
        return GlassCard(tint: Theme.pillsTint) {
            HStack(spacing: 14) {
                Image(systemName: taken ? "checkmark.circle.fill" : "alarm")
                    .font(.title)
                    .foregroundStyle(taken ? Theme.dietTint : Theme.pillsTint)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 3) {
                    Text(schedule.name).font(.body.weight(.medium))
                    Text(schedule.timesLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !taken {
                    Button("Take") { logFromSchedule(schedule) }
                        .buttonStyle(.glass)
                        .tint(Theme.pillsTint)
                        .font(.caption.weight(.semibold))
                } else {
                    Text("Done").font(.caption.weight(.semibold)).foregroundStyle(Theme.dietTint)
                }
            }
            .contextMenu {
                Button(role: .destructive) { delete(schedule) } label: {
                    Label("Delete schedule", systemImage: "trash")
                }
            }
        }
    }

    private func logFromSchedule(_ schedule: MedicationSchedule) {
        withAnimation { context.insert(PillLog(name: schedule.name, purpose: schedule.dose)) }
    }

    private func delete(_ schedule: MedicationSchedule) {
        NotificationService.shared.cancelReminders(ids: schedule.reminderIDs())
        context.delete(schedule)
    }

    @ViewBuilder private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).foregroundStyle(.secondary).padding(.top, 4)
    }

    private func row(_ pill: PillLog) -> some View {
        GlassCard(tint: Theme.pillsTint) {
            HStack(spacing: 14) {
                Image(systemName: "pills.fill")
                    .font(.title)
                    .foregroundStyle(Theme.pillsTint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pill.name).font(.body.weight(.medium))
                    HStack(spacing: 6) {
                        if !pill.purpose.isEmpty {
                            Text("for \(pill.purpose)")
                        }
                        Text(pill.loggedAt.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contextMenu {
                Button(role: .destructive) { context.delete(pill) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    PillsView()
        .modelContainer(DataController.shared.container)
}

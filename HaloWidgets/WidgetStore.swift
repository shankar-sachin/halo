import Foundation
import SwiftData

/// Reads the shared App Group SwiftData store from inside the widget process.
/// Uses a fresh `ModelContext` per call so it can run on WidgetKit's background queues.
enum WidgetStore {
    static let container: ModelContainer = {
        let schema = Schema([
            TodoItem.self, Note.self, DietEntry.self,
            Habit.self, WaterEntry.self, Workout.self, MoodEntry.self, PillLog.self,
            WeightEntry.self, SleepEntry.self, MedicationSchedule.self,
        ])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.identifier))
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // Fallback so the widget never crashes if the store is unavailable.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memory])
    }()

    /// Logs one glass of water directly into the shared store (used by the Control Center control,
    /// which runs in the widget process and can't reach the app's `CommandActions`).
    static func logGlass() {
        let context = ModelContext(container)
        context.insert(WaterEntry(amountML: WaterEntry.glassML))
        try? context.save()
    }

    static func caloriesToday() -> Int {
        let context = ModelContext(container)
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        let descriptor = FetchDescriptor<DietEntry>(
            predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        return entries.reduce(0) { $0 + $1.calories }
    }

    /// Today's habit progress and the best current streak, for the habit widget.
    static func habitStreakSummary() -> HabitStreakSummary {
        let context = ModelContext(container)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        return HabitStreakSummary(
            doneToday: habits.filter { $0.isCompleted() }.count,
            total: habits.count,
            bestStreak: habits.map(\.streak).max() ?? 0
        )
    }

    /// Marks the next incomplete habit done (used by the Control Center control, which has no room
    /// for a picker — same one-tap simplification as `logGlass`). No-op when everything's done.
    static func completeNextHabit() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        let habits = (try? context.fetch(descriptor)) ?? []
        guard let habit = habits.first(where: { !$0.isCompleted() }) else { return }
        habit.toggle()
        try? context.save()
    }

    /// The first scheduled medication not yet logged today, by the same name-matching
    /// `PillsView.takenToday` uses.
    static func nextDueMedication() -> (name: String, dose: String)? {
        let context = ModelContext(container)
        let schedules = (try? context.fetch(FetchDescriptor<MedicationSchedule>(
            predicate: #Predicate { $0.active }
        ))) ?? []
        guard !schedules.isEmpty else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let today = (try? context.fetch(FetchDescriptor<PillLog>(
            predicate: #Predicate { $0.loggedAt >= start }
        ))) ?? []
        let takenNames = Set(today.map { $0.name.lowercased() })
        guard let due = schedules.first(where: { !takenNames.contains($0.name.lowercased()) }) else { return nil }
        return (due.name, due.dose)
    }

    /// Logs the next due medication as taken. No-op when nothing is due.
    static func markMedicationTaken() {
        guard let due = nextDueMedication() else { return }
        let context = ModelContext(container)
        context.insert(PillLog(name: due.name, purpose: due.dose))
        try? context.save()
    }

    static func upcomingTodos(limit: Int) -> [TodoSummary] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.isDone == false },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        let items = (try? context.fetch(descriptor)) ?? []
        return items.prefix(limit).map {
            TodoSummary(title: $0.title, dueDate: $0.dueDate)
        }
    }
}

/// Lightweight, Sendable snapshot of a to-do for the widget timeline.
struct TodoSummary: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let dueDate: Date?
}

/// Lightweight, Sendable snapshot of habit progress for the widget timeline.
struct HabitStreakSummary: Sendable {
    let doneToday: Int
    let total: Int
    let bestStreak: Int
}

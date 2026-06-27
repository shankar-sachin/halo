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

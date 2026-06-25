import Foundation
import SwiftData

/// When a recurring to-do is completed, creates the next occurrence and schedules its reminder.
/// Shared by the UI (`TodoListView`) and voice/Siri completion (`CommandActions`).
@MainActor
enum RecurrenceEngine {
    /// Inserts the next occurrence of `item` if it repeats. Returns the new item, if any.
    @discardableResult
    static func scheduleNext(after item: TodoItem, in context: ModelContext) -> TodoItem? {
        guard item.recurrence != .none, let due = item.dueDate,
              let nextDue = item.recurrence.nextDate(after: due) else { return nil }

        let next = TodoItem(
            title: item.title,
            dueDate: nextDue,
            recurrence: item.recurrence
        )
        context.insert(next)
        try? context.save()

        // Only Sendable values cross into the async reminder scheduling.
        let id = next.persistentModelID.storeIdentifier ?? UUID().uuidString
        let title = next.title
        Task { await NotificationService.shared.scheduleReminder(id: id, title: title, at: nextDue) }
        return next
    }
}

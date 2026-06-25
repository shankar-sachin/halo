import Foundation
import SwiftData

enum Recurrence: String, CaseIterable, Identifiable {
    case none, daily, weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Never"
        case .daily: "Daily"
        case .weekly: "Weekly"
        }
    }

    /// The next due date after `date`, or `nil` for non-repeating.
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none: nil
        case .daily: calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        }
    }
}

@Model
final class TodoItem {
    var title: String
    var dueDate: Date?
    var isDone: Bool
    var completedAt: Date?
    var createdAt: Date
    var recurrenceRaw: String = Recurrence.none.rawValue

    init(
        title: String,
        dueDate: Date? = nil,
        isDone: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        recurrence: Recurrence = .none
    ) {
        self.title = title
        self.dueDate = dueDate
        self.isDone = isDone
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.recurrenceRaw = recurrence.rawValue
    }

    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard !isDone, let dueDate else { return false }
        return dueDate < .now
    }
}

import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var createdAt: Date
    /// Calendar days (start-of-day) on which the habit was completed.
    var completionDates: [Date]

    init(name: String, createdAt: Date = .now, completionDates: [Date] = []) {
        self.name = name
        self.createdAt = createdAt
        self.completionDates = completionDates
    }

    func isCompleted(on day: Date = .now, calendar: Calendar = .current) -> Bool {
        completionDates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    func toggle(on day: Date = .now, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: day)
        if let index = completionDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) {
            completionDates.remove(at: index)
        } else {
            completionDates.append(start)
        }
    }

    /// Consecutive days completed up to and including today.
    var streak: Int {
        let calendar = Calendar.current
        let days = Set(completionDates.map { calendar.startOfDay(for: $0) })
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        // Allow the streak to count from today or yesterday.
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), days.contains(yesterday) else {
                return 0
            }
            day = yesterday
        }
        while days.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}

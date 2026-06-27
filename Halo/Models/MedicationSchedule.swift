import Foundation
import SwiftData

/// A recurring medication/supplement the user wants to be reminded about. The actual doses taken
/// are still recorded as `PillLog` entries; adherence compares this schedule against those logs.
@Model
final class MedicationSchedule {
    var name: String
    /// Optional dose description, e.g. "1000 IU" or "2 tablets".
    var dose: String
    /// Times of day to take it, stored as minutes from midnight (e.g. 540 = 9:00 AM).
    var timesMinutesOfDay: [Int]
    var active: Bool
    var createdAt: Date

    init(name: String, dose: String = "", timesMinutesOfDay: [Int] = [], active: Bool = true, createdAt: Date = .now) {
        self.name = name
        self.dose = dose
        self.timesMinutesOfDay = timesMinutesOfDay
        self.active = active
        self.createdAt = createdAt
    }

    /// Notification identifiers for this schedule's reminders (one per time).
    func reminderIDs() -> [String] {
        let base = persistentModelID.storeIdentifier ?? "\(name)"
        return timesMinutesOfDay.map { "med-\(base)-\($0)" }
    }

    /// "9:00 AM, 9:00 PM" style summary of the scheduled times.
    var timesLabel: String {
        timesMinutesOfDay.sorted().map { minutes in
            var comps = DateComponents()
            comps.hour = minutes / 60
            comps.minute = minutes % 60
            let date = Calendar.current.date(from: comps) ?? .now
            return date.formatted(date: .omitted, time: .shortened)
        }.joined(separator: ", ")
    }
}

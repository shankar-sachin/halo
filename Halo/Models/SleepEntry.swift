import Foundation
import SwiftData

/// A night's sleep, logged manually/by voice. Apple Health nights are read read-only and
/// merged into the list (see `HealthKitService.recentSleep`), not persisted here.
@Model
final class SleepEntry {
    var hoursAsleep: Double
    /// The morning the user woke — used to bucket the night by day.
    var loggedAt: Date

    init(hoursAsleep: Double, loggedAt: Date = .now) {
        self.hoursAsleep = hoursAsleep
        self.loggedAt = loggedAt
    }

    /// "7h 30m" style label.
    var label: String {
        let h = Int(hoursAsleep)
        let m = Int((hoursAsleep - Double(h)) * 60)
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

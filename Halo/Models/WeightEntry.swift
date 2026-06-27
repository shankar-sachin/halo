import Foundation
import SwiftData

/// A body-weight measurement. Logged manually/by voice, or read read-only from Apple Health.
@Model
final class WeightEntry {
    var weightKg: Double
    var loggedAt: Date
    /// "manual" for in-app/voice logs, "health" for entries mirrored from Apple Health.
    var sourceRaw: String

    init(weightKg: Double, loggedAt: Date = .now, source: String = "manual") {
        self.weightKg = weightKg
        self.loggedAt = loggedAt
        self.sourceRaw = source
    }

    /// Weight in pounds, for display when the user prefers imperial.
    var pounds: Double { weightKg * 2.2046226218 }
}

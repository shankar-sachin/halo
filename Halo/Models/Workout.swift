import Foundation
import SwiftData

@Model
final class Workout {
    var type: String
    var durationMinutes: Int
    var calories: Int
    var loggedAt: Date

    init(type: String, durationMinutes: Int, calories: Int = 0, loggedAt: Date = .now) {
        self.type = type
        self.durationMinutes = durationMinutes
        self.calories = calories
        self.loggedAt = loggedAt
    }

    /// SF Symbol guessed from the workout type.
    var symbol: String {
        let t = type.lowercased()
        if t.contains("run") { return "figure.run" }
        if t.contains("walk") { return "figure.walk" }
        if t.contains("bik") || t.contains("cycl") { return "figure.outdoor.cycle" }
        if t.contains("swim") { return "figure.pool.swim" }
        if t.contains("yoga") { return "figure.yoga" }
        if t.contains("lift") || t.contains("weight") || t.contains("strength") { return "dumbbell.fill" }
        if t.contains("hik") { return "figure.hiking" }
        return "figure.mixed.cardio"
    }
}

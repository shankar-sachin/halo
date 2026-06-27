import Foundation
import ActivityKit

/// Shared Live Activity descriptor for an in-progress workout. Lives in `Models` so both the app
/// (which starts/ends the activity) and the widget extension (which renders it) can see it.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the workout started — the Lock Screen / Dynamic Island shows a live timer from this.
        var startedAt: Date
        var type: String
        var symbol: String
    }

    /// The workout type, fixed for the life of the activity.
    var workoutType: String
}

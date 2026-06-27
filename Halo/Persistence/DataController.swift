import Foundation
import SwiftData

/// A single shared `ModelContainer` used by both the SwiftUI app and the App Intents,
/// so that entries created by Siri appear immediately in the running app.
@MainActor
final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            TodoItem.self,
            Note.self,
            DietEntry.self,
            Habit.self,
            WaterEntry.self,
            Workout.self,
            MoodEntry.self,
            PillLog.self,
            WeightEntry.self,
            SleepEntry.self,
            MedicationSchedule.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier)
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

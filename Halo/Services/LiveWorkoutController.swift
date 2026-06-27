import Foundation
import ActivityKit
import SwiftData
import WidgetKit

/// Starts/ends a workout Live Activity (Lock Screen + Dynamic Island) and logs the resulting
/// `Workout` when finished. No-ops gracefully when Live Activities are unavailable.
@MainActor
@Observable
final class LiveWorkoutController {
    private(set) var activeType: String?
    private(set) var startedAt: Date?
    @ObservationIgnored private var activity: Activity<WorkoutActivityAttributes>?

    var isActive: Bool { activity != nil }

    func start(type: String, symbol: String) {
        guard activity == nil, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now = Date()
        let state = WorkoutActivityAttributes.ContentState(startedAt: now, type: type, symbol: symbol)
        let attributes = WorkoutActivityAttributes(workoutType: type)
        do {
            activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            activeType = type
            startedAt = now
        } catch {
            activity = nil
        }
    }

    /// Ends the activity and logs the workout with an estimated calorie burn.
    func finish(in context: ModelContext) async {
        guard isActive, let startedAt, let activeType else { return }
        self.activity = nil
        self.activeType = nil
        self.startedAt = nil

        let minutes = max(Int(Date().timeIntervalSince(startedAt) / 60), 1)
        let calories = await HaloIntelligence.estimateWorkoutKcal(type: activeType, minutes: minutes)
            ?? WorkoutCalories.estimate(type: activeType, minutes: minutes)
        context.insert(Workout(type: activeType, durationMinutes: minutes, calories: calories))
        try? context.save()

        await Self.endAll()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func cancel() async {
        activity = nil
        activeType = nil
        startedAt = nil
        await Self.endAll()
    }

    /// Ends every in-flight workout activity. `nonisolated` so the (non-Sendable) `Activity` values
    /// are obtained and ended entirely off the main actor, never crossing an isolation boundary.
    nonisolated static func endAll() async {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

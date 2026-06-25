import Foundation
import SwiftData

/// Single entry point for logging a meal: persists it, optionally syncs to Health,
/// and fires the calorie-budget notification. Shared by the UI and the App Intents.
@MainActor
struct MealLogger {
    let context: ModelContext

    /// Logs a meal and returns the resulting entry plus today's running total.
    @discardableResult
    func log(foodText: String, calories: Int, at date: Date = .now, source: CalorieSource, protein: Int = 0, carbs: Int = 0, fat: Int = 0) async -> (entry: DietEntry, consumedToday: Int) {
        let entry = DietEntry(foodText: foodText, calories: calories, loggedAt: date, source: source, protein: protein, carbs: carbs, fat: fat)
        context.insert(entry)
        try? context.save()

        let consumed = consumedToday(referenceDate: date)

        if UserDefaults.shared.bool(forKey: SettingsKey.syncToHealth) {
            await HealthKitService.shared.save(calories: calories, at: date)
        }
        await NotificationService.shared.notifyMealLogged(consumed: consumed, budget: SettingsDefault.budget)

        return (entry, consumed)
    }

    /// Per-day calorie totals for the last `days` days, oldest first (includes zero days).
    func dailyTotals(days: Int, referenceDate: Date = .now) -> [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        guard let earliest = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        let descriptor = FetchDescriptor<DietEntry>(
            predicate: #Predicate { $0.loggedAt >= earliest }
        )
        let entries = (try? context.fetch(descriptor)) ?? []

        var totals: [Date: Int] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.loggedAt)
            totals[day, default: 0] += entry.calories
        }

        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: earliest) else { return nil }
            return (day, totals[day] ?? 0)
        }
    }

    /// Number of consecutive days up to today with at least one logged meal.
    func currentStreak(referenceDate: Date = .now) -> Int {
        let totals = dailyTotals(days: 60, referenceDate: referenceDate).reversed()
        var streak = 0
        for day in totals {
            if day.calories > 0 { streak += 1 } else { break }
        }
        return streak
    }

    /// Sum of calories logged on the same calendar day as `referenceDate`.
    func consumedToday(referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        guard
            let start = calendar.dateInterval(of: .day, for: referenceDate)?.start,
            let end = calendar.dateInterval(of: .day, for: referenceDate)?.end
        else { return 0 }

        let descriptor = FetchDescriptor<DietEntry>(
            predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        return entries.reduce(0) { $0 + $1.calories }
    }
}

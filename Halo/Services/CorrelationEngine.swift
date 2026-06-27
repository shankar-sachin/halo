import Foundation
import SwiftData

/// One detected pattern, e.g. "Your mood averages 4.2 on workout days vs 3.1 on rest days."
struct Correlation: Identifiable, Sendable {
    let id = UUID()
    let headline: String
    /// Absolute effect size used for ranking (e.g. a mood-point difference).
    let delta: Double
    let symbol: String
}

/// Finds cross-tracker patterns deterministically in Swift. Numbers come from here; the AI only
/// words the top finding (see `HaloIntelligence.correlationInsight`). A minimum-sample guard keeps
/// noise from being reported as a trend.
struct CorrelationEngine {
    /// Minimum days required on each side of a comparison before it's trustworthy.
    static let minSamples = 3
    /// Minimum mood-point difference worth surfacing.
    static let minMoodDelta = 0.3

    /// Per-day rollup of the trackers that participate in correlations.
    private struct Day {
        var moodSum = 0
        var moodCount = 0
        var workoutMinutes = 0
        var waterML = 0
        var habitsDone = 0
        var sleepHours: Double?
        var moodAvg: Double? { moodCount > 0 ? Double(moodSum) / Double(moodCount) : nil }
    }

    /// Pure entry point — pass already-fetched data so this stays testable.
    static func correlations(
        moods: [MoodEntry],
        workouts: [Workout],
        water: [WaterEntry],
        habits: [Habit],
        sleeps: [SleepEntry],
        waterGoal: Int,
        sleepGoal: Int,
        days: Int = 21,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Correlation] {
        let today = calendar.startOfDay(for: now)
        guard let earliest = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        var buckets: [Date: Day] = [:]
        func day(_ date: Date) -> Date { calendar.startOfDay(for: date) }
        func inRange(_ date: Date) -> Bool { date >= earliest && date <= now }

        for m in moods where inRange(m.loggedAt) {
            buckets[day(m.loggedAt), default: Day()].moodSum += m.rating
            buckets[day(m.loggedAt), default: Day()].moodCount += 1
        }
        for w in workouts where inRange(w.loggedAt) {
            buckets[day(w.loggedAt), default: Day()].workoutMinutes += w.durationMinutes
        }
        for e in water where inRange(e.loggedAt) {
            buckets[day(e.loggedAt), default: Day()].waterML += e.amountML
        }
        for s in sleeps where inRange(s.loggedAt) {
            buckets[day(s.loggedAt), default: Day()].sleepHours = s.hoursAsleep
        }
        for habit in habits {
            for date in habit.completionDates where inRange(date) {
                buckets[day(date), default: Day()].habitsDone += 1
            }
        }

        // Only days where the user logged a mood can contribute to a mood contrast.
        let moodDays = buckets.values.filter { $0.moodAvg != nil }
        guard moodDays.count >= minSamples * 2 else { return [] }

        var found: [Correlation] = []

        func moodContrast(_ headline: (Double, Double) -> String, symbol: String, partition: (Day) -> Bool) {
            let yes = moodDays.filter(partition).compactMap(\.moodAvg)
            let no = moodDays.filter { !partition($0) }.compactMap(\.moodAvg)
            guard yes.count >= minSamples, no.count >= minSamples else { return }
            let a = yes.reduce(0, +) / Double(yes.count)
            let b = no.reduce(0, +) / Double(no.count)
            guard abs(a - b) >= minMoodDelta else { return }
            found.append(Correlation(headline: headline(a, b), delta: abs(a - b), symbol: symbol))
        }

        moodContrast({ a, b in
            "Your mood averages \(fmt(a)) on workout days vs \(fmt(b)) on rest days."
        }, symbol: "figure.run") { $0.workoutMinutes > 0 }

        moodContrast({ a, b in
            "Your mood averages \(fmt(a)) on days you hit your water goal vs \(fmt(b)) when you don't."
        }, symbol: "drop.fill") { $0.waterML >= waterGoal }

        moodContrast({ a, b in
            "Your mood averages \(fmt(a)) on days you keep up your habits vs \(fmt(b)) when you skip them."
        }, symbol: "checkmark.seal.fill") { $0.habitsDone > 0 }

        if sleeps.contains(where: { inRange($0.loggedAt) }) {
            moodContrast({ a, b in
                "Your mood averages \(fmt(a)) after \(sleepGoal)h+ of sleep vs \(fmt(b)) on shorter nights."
            }, symbol: "bed.double.fill") { ($0.sleepHours ?? 0) >= Double(sleepGoal) }
        }

        return found.sorted { $0.delta > $1.delta }
    }

    private static func fmt(_ value: Double) -> String { String(format: "%.1f", value) }

    // MARK: - Context convenience

    @MainActor
    static func correlations(in context: ModelContext, days: Int = 21) -> [Correlation] {
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        let workouts = (try? context.fetch(FetchDescriptor<Workout>())) ?? []
        let water = (try? context.fetch(FetchDescriptor<WaterEntry>())) ?? []
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        let sleeps = (try? context.fetch(FetchDescriptor<SleepEntry>())) ?? []
        return correlations(
            moods: moods, workouts: workouts, water: water, habits: habits, sleeps: sleeps,
            waterGoal: SettingsDefault.waterGoal, sleepGoal: SettingsDefault.sleepGoal, days: days
        )
    }
}

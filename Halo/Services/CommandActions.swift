import Foundation
import SwiftData

/// Shared business logic behind both Siri App Intents and the in-app "Halo" voice mode.
/// Each method takes a raw spoken phrase and returns a spoken-style confirmation string.
@MainActor
struct CommandActions {
    var context: ModelContext = DataController.shared.container.mainContext

    private let parser = DateTimeParser()

    // MARK: - To-Do

    func addTodo(_ raw: String) async -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "I didn't catch the to-do." }

        let dueDate = parser.parseDate(from: text)
        let title = dueDate != nil ? parser.strippedTitle(from: text) : text
        let item = TodoItem(title: title.isEmpty ? text : title, dueDate: dueDate)
        context.insert(item)
        try? context.save()

        if let dueDate {
            await NotificationService.shared.scheduleReminder(
                id: item.persistentModelID.storeIdentifier ?? UUID().uuidString,
                title: item.title,
                at: dueDate
            )
            let when = dueDate.formatted(date: .omitted, time: .shortened)
            return "Added “\(item.title)” and I'll remind you at \(when)."
        }
        return "Added “\(item.title)” to your to-dos."
    }

    func completeTodo(_ raw: String) async -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "What did you finish?" }

        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.isDone == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let open = (try? context.fetch(descriptor)) ?? []
        guard !open.isEmpty else { return "You don't have any open to-dos right now." }

        let completionTime = parser.parseDate(from: text) ?? .now
        let searchText = parser.strippedTitle(from: text)
        guard let index = TodoMatcher().bestMatchIndex(for: searchText, in: open.map(\.title)) else {
            return "I couldn't find a matching to-do for “\(searchText)”."
        }

        let item = open[index]
        item.isDone = true
        item.completedAt = completionTime
        try? context.save()
        NotificationService.shared.cancelReminder(id: item.persistentModelID.storeIdentifier ?? "")
        RecurrenceEngine.scheduleNext(after: item, in: context)

        let when = completionTime.formatted(date: .omitted, time: .shortened)
        return "Nice — marked “\(item.title)” done at \(when)."
    }

    // MARK: - Notes

    func addNote(_ raw: String) async -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "I didn't catch the note." }
        context.insert(Note(body: text))
        try? context.save()
        return "Saved your note."
    }

    // MARK: - Diet

    func logMeal(_ raw: String) async -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "What did you eat?" }

        let loggedAt = parser.parseDate(from: text) ?? .now
        let stripped = parser.strippedTitle(from: text)
        let foodText = stripped.isEmpty ? text : stripped

        let estimate = await CalorieEstimator.shared.estimate(for: foodText)
        let result = await MealLogger(context: context).log(
            foodText: foodText,
            calories: estimate.calories,
            at: loggedAt,
            source: estimate.source
        )

        let remaining = max(SettingsDefault.budget - result.consumedToday, 0)
        if estimate.calories <= 0 {
            return "Logged “\(foodText)”. I couldn't estimate the calories — you can set them in the app."
        }
        return "Logged \(estimate.calories) calories for \(foodText). You have \(remaining) left today."
    }

    // MARK: - Water

    func logWater(_ raw: String) async -> String {
        let ml = VoiceParsing.waterML(from: raw)
        context.insert(WaterEntry(amountML: ml))
        try? context.save()
        let total = todaysWater()
        return "Logged \(ml) ml of water — \(total) ml today."
    }

    private func todaysWater() -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let descriptor = FetchDescriptor<WaterEntry>(predicate: #Predicate { $0.loggedAt >= start })
        return ((try? context.fetch(descriptor)) ?? []).reduce(0) { $0 + $1.amountML }
    }

    // MARK: - Workouts

    func logWorkout(_ raw: String) async -> String {
        let parsed = VoiceParsing.workout(from: raw)
        context.insert(Workout(type: parsed.type, durationMinutes: parsed.minutes))
        try? context.save()
        return "Logged a \(parsed.minutes) minute \(parsed.type.lowercased())."
    }

    // MARK: - Mood

    func logMood(_ raw: String) async -> String {
        guard let rating = MoodEntry.rating(from: raw) else {
            return "Tell me how you feel — great, good, okay, low, or awful."
        }
        context.insert(MoodEntry(rating: rating, note: ""))
        try? context.save()
        return "Logged your mood as \(MoodEntry.label(for: rating)) \(MoodEntry.emoji(for: rating))."
    }

    // MARK: - Pills

    func logPill(_ raw: String) async -> String {
        let parsed = VoiceParsing.pill(from: raw)
        guard !parsed.name.isEmpty else { return "Which pill did you take?" }
        context.insert(PillLog(name: parsed.name, purpose: parsed.purpose))
        try? context.save()
        if parsed.purpose.isEmpty { return "Logged your \(parsed.name)." }
        return "Logged your \(parsed.name) for \(parsed.purpose)."
    }

    // MARK: - Habits

    func addHabit(_ raw: String) async -> String {
        let name = VoiceParsing.habitName(from: raw)
        guard !name.isEmpty else { return "What habit would you like to add?" }
        context.insert(Habit(name: name.capitalized))
        try? context.save()
        return "Added the habit “\(name.capitalized)”."
    }

    func completeHabit(_ raw: String) async -> String {
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(descriptor)) ?? []
        guard !habits.isEmpty else { return "You don't have any habits yet." }

        let searchText = VoiceParsing.habitSearchText(from: raw)
        guard let index = TodoMatcher().bestMatchIndex(for: searchText, in: habits.map(\.name)) else {
            return "I couldn't find a habit matching “\(searchText)”."
        }
        let habit = habits[index]
        if !habit.isCompleted() {
            habit.toggle()
            try? context.save()
        }
        return "Marked “\(habit.name)” done — \(habit.streak) day streak! 🔥"
    }
}

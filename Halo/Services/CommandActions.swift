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
            source: estimate.source,
            protein: estimate.protein,
            carbs: estimate.carbs,
            fat: estimate.fat
        )

        let remaining = max(SettingsDefault.budget - result.consumedToday, 0)
        if estimate.calories <= 0 {
            return "Logged “\(foodText)”. I couldn't estimate the calories — you can set them in the app."
        }
        let macros = estimate.hasMacros
            ? " (\(estimate.protein)g protein, \(estimate.carbs)g carbs, \(estimate.fat)g fat)"
            : ""
        return "Logged \(estimate.calories) calories\(macros) for \(foodText). You have \(remaining) left today."
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
        // AI estimate of calories burned, falling back to a deterministic MET-based estimate.
        let calories = await HaloIntelligence.estimateWorkoutKcal(type: parsed.type, minutes: parsed.minutes)
            ?? WorkoutCalories.estimate(type: parsed.type, minutes: parsed.minutes)
        context.insert(Workout(type: parsed.type, durationMinutes: parsed.minutes, calories: calories))
        try? context.save()
        let burn = calories > 0 ? " — about \(calories) kcal burned" : ""
        return "Logged a \(parsed.minutes) minute \(parsed.type.lowercased())\(burn)."
    }

    // MARK: - Mood

    func logMood(_ raw: String) async -> String {
        // Prefer AI journaling (rating + reflective note + supportive reply); fall back to keywords.
        if let reflection = await HaloIntelligence.reflectMood(raw) {
            context.insert(MoodEntry(rating: reflection.rating, note: reflection.note))
            try? context.save()
            let reply = reflection.reply.isEmpty ? "" : " \(reflection.reply)"
            return "Logged your mood as \(MoodEntry.label(for: reflection.rating)) \(MoodEntry.emoji(for: reflection.rating)).\(reply)"
        }
        guard let rating = MoodEntry.rating(from: raw) else {
            return "Tell me how you feel — great, good, okay, low, or awful."
        }
        context.insert(MoodEntry(rating: rating, note: raw.trimmingCharacters(in: .whitespacesAndNewlines)))
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

    // MARK: - Ask Halo (queries)

    /// Answers a spoken question by reading the user's data. Numbers are computed exactly from
    /// SwiftData — the AI only routes the question here, it never invents figures.
    func answer(_ raw: String) async -> String {
        let lower = raw.lowercased()

        if lower.contains("calorie") || lower.contains("budget") || lower.contains("eaten")
            || lower.contains("food") || lower.contains("diet") {
            let consumed = MealLogger(context: context).consumedToday()
            return TreatSuggester().message(consumed: consumed, budget: SettingsDefault.budget).body
        }
        if lower.contains("water") || lower.contains("hydrat") || lower.contains("drink") || lower.contains("drank") {
            let total = todaysWater()
            let goal = SettingsDefault.waterGoal
            let remaining = max(goal - total, 0)
            return remaining > 0
                ? "You've had \(total) ml of water today — \(remaining) ml to go to hit \(goal) ml."
                : "You've had \(total) ml of water today — you've hit your \(goal) ml goal. 💧"
        }
        if lower.contains("habit") {
            let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            guard !habits.isEmpty else { return "You don't have any habits yet." }
            let done = habits.filter { $0.isCompleted() }.count
            let best = habits.map(\.streak).max() ?? 0
            return "You've done \(done) of \(habits.count) habits today. Best streak: \(best) day\(best == 1 ? "" : "s")."
        }
        if lower.contains("mood") || lower.contains("feel") {
            var descriptor = FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)])
            descriptor.fetchLimit = 1
            guard let mood = (try? context.fetch(descriptor))?.first else { return "You haven't logged a mood yet." }
            return "Your last mood was \(MoodEntry.label(for: mood.rating)) \(mood.emoji)."
        }
        if lower.contains("workout") || lower.contains("exercise") || lower.contains("gym") {
            let (start, end) = Self.todayInterval()
            let workouts = (try? context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end }))) ?? []
            guard !workouts.isEmpty else { return "No workouts logged today." }
            let minutes = workouts.reduce(0) { $0 + $1.durationMinutes }
            return "You've logged \(workouts.count) workout\(workouts.count == 1 ? "" : "s") today — \(minutes) minutes total."
        }
        if lower.contains("pill") || lower.contains("medication") || lower.contains("vitamin") || lower.contains("supplement") {
            let (start, end) = Self.todayInterval()
            let pills = (try? context.fetch(FetchDescriptor<PillLog>(predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end }))) ?? []
            guard !pills.isEmpty else { return "No pills logged today." }
            return "You've logged \(pills.count) today: \(pills.map(\.name).joined(separator: ", "))."
        }

        // Default: open to-dos ("what's on my list", "what do I have to do").
        let open = openTodos()
        guard !open.isEmpty else { return "You're all caught up — no open to-dos." }
        let preview = open.prefix(3).map { "“\($0.title)”" }.joined(separator: ", ")
        let more = open.count > 3 ? " and \(open.count - 3) more" : ""
        return "You have \(open.count) open to-do\(open.count == 1 ? "" : "s"): \(preview)\(more)."
    }

    // MARK: - Daily briefing

    /// A spoken recap of today across the trackers.
    func dailyBriefing() async -> String {
        let consumed = MealLogger(context: context).consumedToday()
        let budget = SettingsDefault.budget
        let calLine = consumed > 0
            ? "🍽️ \(consumed) of \(budget) kcal — \(max(budget - consumed, 0)) left"
            : "🍽️ No meals logged yet"

        let waterLine = "💧 \(todaysWater()) of \(SettingsDefault.waterGoal) ml water"

        let open = openTodos()
        let todoLine = open.isEmpty ? "✅ No open to-dos" : "✅ \(open.count) open to-do\(open.count == 1 ? "" : "s")"

        var lines = [calLine, waterLine, todoLine]

        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        if !habits.isEmpty {
            lines.append("🔁 \(habits.filter { $0.isCompleted() }.count)/\(habits.count) habits done")
        }

        // Let the on-device model phrase a warm recap from the exact figures; fall back to the list.
        if let polished = await HaloIntelligence.polishBriefing(facts: lines.joined(separator: "\n")) {
            return polished
        }
        return (["Here's your day:"] + lines).joined(separator: "\n")
    }

    // MARK: - Weekly insights

    /// An AI (or templated) summary of the last 7 days across diet, water, and habits.
    func weeklyInsights() async -> String {
        let logger = MealLogger(context: context)
        let week = logger.dailyTotals(days: 7)
        let avg = week.isEmpty ? 0 : week.reduce(0) { $0 + $1.calories } / week.count
        let loggedDays = week.filter { $0.calories > 0 }.count
        let streak = logger.currentStreak()
        let budget = SettingsDefault.budget

        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        let bestStreak = habits.map(\.streak).max() ?? 0

        let facts = """
        Daily calorie budget: \(budget) kcal.
        Average calories/day this week: \(avg) kcal across \(loggedDays) logged days.
        Current meal-logging streak: \(streak) days.
        Habits tracked: \(habits.count); best habit streak: \(bestStreak) days.
        """

        if let insight = await HaloIntelligence.weeklyInsight(facts: facts) {
            return insight
        }
        // Deterministic fallback.
        let vsBudget = avg == 0 ? "no meals logged yet" :
            (avg <= budget ? "averaging \(avg) kcal/day, under your \(budget) goal — nice work"
                           : "averaging \(avg) kcal/day, over your \(budget) goal")
        return "This week: \(vsBudget). \(streak)-day logging streak\(bestStreak > 0 ? ", best habit streak \(bestStreak) days" : "")."
    }

    // MARK: - Meal suggestions

    /// Suggests meals that fit the remaining calorie budget (AI, with a static fallback).
    func suggestMeal(_ raw: String) async -> String {
        let consumed = MealLogger(context: context).consumedToday()
        let remaining = max(SettingsDefault.budget - consumed, 0)

        if let ideas = await HaloIntelligence.suggestMeals(remaining: remaining, context: raw) {
            return ideas
        }
        // Deterministic fallback keyed by remaining budget.
        if remaining <= 0 { return "You're at your budget for today — maybe a light option like a herbal tea or some veg sticks. 🥕" }
        if remaining < 300 { return "About \(remaining) kcal left — a greek yogurt with berries (~150) or a boiled egg and fruit (~200) would fit." }
        if remaining < 600 { return "About \(remaining) kcal left — a chicken salad (~400) or a veggie wrap (~450) would fit nicely." }
        return "You have \(remaining) kcal left — room for a salmon bowl (~550), a burrito (~600), or pasta with veg (~650)."
    }

    // MARK: - Notes → to-dos

    /// Turns a note into to-dos: extracts tasks (AI, with a split-based fallback) and creates them.
    func extractTodosFromNote(_ raw: String) async -> String {
        let target = Self.targetText(from: raw)
        let notes = (try? context.fetch(FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        guard !notes.isEmpty else { return "You don't have any notes to pull to-dos from." }

        let note: Note
        if !target.isEmpty, let index = TodoMatcher().bestMatchIndex(for: target, in: notes.map(\.title)) {
            note = notes[index]
        } else {
            note = notes[0]
        }

        let tasks = await HaloIntelligence.extractTasks(from: note.body) ?? Self.splitTasks(note.body)
        guard !tasks.isEmpty else { return "I couldn't find any tasks in that note." }

        for task in tasks {
            context.insert(TodoItem(title: task))
        }
        try? context.save()
        return "Created \(tasks.count) to-do\(tasks.count == 1 ? "" : "s") from your note."
    }

    /// Deterministic fallback: split a note into candidate tasks on lines, commas, and "and".
    static func splitTasks(_ body: String) -> [String] {
        body
            .split(whereSeparator: { $0 == "\n" || $0 == "," || $0 == ";" })
            .flatMap { $0.lowercased().contains(" and ") ? $0.components(separatedBy: " and ") : [String($0)] }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }
    }

    // MARK: - Edit & delete

    /// Removes an entry by voice — to-dos/notes/habits by fuzzy title, or the latest entry of a
    /// named tracker ("delete my last water").
    func deleteEntry(_ raw: String) async -> String {
        let lower = raw.lowercased()
        let target = Self.targetText(from: raw)

        if lower.contains("note") {
            let notes = (try? context.fetch(FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
            guard !notes.isEmpty else { return "You don't have any notes to delete." }
            if !target.isEmpty, let index = TodoMatcher().bestMatchIndex(for: target, in: notes.map(\.title)) {
                let note = notes[index]; context.delete(note); try? context.save()
                return "Deleted the note “\(note.title)”."
            }
            let note = notes[0]; context.delete(note); try? context.save()
            return "Deleted your latest note."
        }
        if lower.contains("habit") {
            let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            guard !habits.isEmpty else { return "You don't have any habits." }
            guard let index = TodoMatcher().bestMatchIndex(for: target, in: habits.map(\.name)) else {
                return "I couldn't find a habit matching “\(target)”."
            }
            let habit = habits[index]; context.delete(habit); try? context.save()
            return "Deleted the habit “\(habit.name)”."
        }
        if lower.contains("water") { return deleteLatestWater() }
        if lower.contains("workout") || lower.contains("exercise") { return deleteLatestWorkout() }
        if lower.contains("pill") || lower.contains("medication") || lower.contains("vitamin") || lower.contains("supplement") { return deleteLatestPill() }
        if lower.contains("mood") { return deleteLatestMood() }
        if lower.contains("meal") || lower.contains("food") { return deleteLatestMeal() }

        // Default: a to-do, matched by title.
        let todos = (try? context.fetch(FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        guard !todos.isEmpty else { return "You don't have any to-dos to delete." }
        let search = target.isEmpty ? raw : target
        guard let index = TodoMatcher().bestMatchIndex(for: search, in: todos.map(\.title)) else {
            return "I couldn't find a to-do matching “\(search)”."
        }
        let item = todos[index]
        NotificationService.shared.cancelReminder(id: item.persistentModelID.storeIdentifier ?? "")
        context.delete(item); try? context.save()
        return "Deleted the to-do “\(item.title)”."
    }

    /// Renames or reschedules an existing to-do by voice ("reschedule call mom to 7pm",
    /// "rename groceries to buy oat milk").
    func editTodo(_ raw: String) async -> String {
        let open = openTodos()
        guard !open.isEmpty else { return "You don't have any open to-dos to change." }

        var targetPart = raw
        var changePart = ""
        if let range = raw.range(of: " to ", options: [.caseInsensitive, .backwards]) {
            targetPart = String(raw[..<range.lowerBound])
            changePart = String(raw[range.upperBound...])
        }
        let targetText = Self.targetText(from: targetPart)
        let search = targetText.isEmpty ? Self.targetText(from: raw) : targetText
        guard let index = TodoMatcher().bestMatchIndex(for: search, in: open.map(\.title)) else {
            return "I couldn't find a to-do matching “\(search)”."
        }
        let item = open[index]

        // A parseable time → reschedule; otherwise rename to the change text.
        if let newDate = parser.parseDate(from: changePart.isEmpty ? raw : changePart) {
            item.dueDate = newDate
            try? context.save()
            await NotificationService.shared.scheduleReminder(
                id: item.persistentModelID.storeIdentifier ?? UUID().uuidString,
                title: item.title,
                at: newDate
            )
            let when = newDate.formatted(date: .abbreviated, time: .shortened)
            return "Rescheduled “\(item.title)” to \(when)."
        }
        let newTitle = changePart.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTitle.isEmpty else { return "Tell me how to change it — a new time or a new name." }
        let old = item.title
        item.title = newTitle
        try? context.save()
        return "Renamed “\(old)” to “\(newTitle)”."
    }

    // MARK: - Helpers

    private func openTodos() -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.isDone == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func deleteLatestWater() -> String {
        var d = FetchDescriptor<WaterEntry>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]); d.fetchLimit = 1
        guard let entry = (try? context.fetch(d))?.first else { return "No water entries to delete." }
        context.delete(entry); try? context.save()
        return "Deleted your last water entry (\(entry.amountML) ml)."
    }

    private func deleteLatestWorkout() -> String {
        var d = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]); d.fetchLimit = 1
        guard let entry = (try? context.fetch(d))?.first else { return "No workouts to delete." }
        context.delete(entry); try? context.save()
        return "Deleted your last \(entry.type.lowercased()) workout."
    }

    private func deleteLatestPill() -> String {
        var d = FetchDescriptor<PillLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]); d.fetchLimit = 1
        guard let entry = (try? context.fetch(d))?.first else { return "No pills to delete." }
        context.delete(entry); try? context.save()
        return "Deleted your last \(entry.name)."
    }

    private func deleteLatestMood() -> String {
        var d = FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]); d.fetchLimit = 1
        guard let entry = (try? context.fetch(d))?.first else { return "No mood entries to delete." }
        context.delete(entry); try? context.save()
        return "Deleted your last mood entry."
    }

    private func deleteLatestMeal() -> String {
        var d = FetchDescriptor<DietEntry>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]); d.fetchLimit = 1
        guard let entry = (try? context.fetch(d))?.first else { return "No meals to delete." }
        context.delete(entry); try? context.save()
        return "Deleted your last meal (\(entry.foodText))."
    }

    private static func todayInterval() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        return (start, end)
    }

    /// Strips routing verbs, articles, and tracker nouns to leave the descriptive target text.
    private static func targetText(from raw: String) -> String {
        let stop: Set<String> = [
            "delete", "remove", "cancel", "clear", "change", "rename", "reschedule", "edit", "update",
            "move", "get", "rid", "of", "set",
            "the", "my", "a", "an", "that", "this", "last", "latest", "recent",
            "to-do", "todo", "task", "note", "habit", "water", "workout", "exercise",
            "pill", "pills", "medication", "vitamin", "supplement", "mood", "meal", "food", "entry", "log",
        ]
        let words = raw.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        return words.filter { !stop.contains($0) }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}

import Foundation

/// Turns a free-form spoken transcript ("Halo, add a to-do …") into an action.
/// `classify` is pure (used by tests); `handle` executes via `CommandActions`.
@MainActor
struct VoiceCommandRouter {
    enum Action: String {
        case todo, note, meal, complete, water, workout, mood, habit, addHabit, pill, unknown

        var systemImage: String {
            switch self {
            case .todo: "checklist"
            case .note: "note.text"
            case .meal: "fork.knife"
            case .complete: "checkmark.circle"
            case .water: "drop.fill"
            case .workout: "figure.run"
            case .mood: "face.smiling"
            case .habit, .addHabit: "checkmark.seal"
            case .pill: "pills.fill"
            case .unknown: "questionmark.circle"
            }
        }
    }

    private static let wakeWords = ["hey halo", "okay halo", "ok halo", "halo"]

    private static let prefixes: [(Action, [String])] = [
        (.complete, ["i have finished", "i've finished", "i finished", "finished",
                     "i have completed", "i completed", "completed", "mark done",
                     "i am done with", "i'm done with", "done with"]),
        (.note, ["add a note that", "add a note", "make a note that", "make a note",
                 "take a note that", "take a note", "note that", "new note", "note"]),
        (.meal, ["log that i ate", "log that i had", "log a meal", "log food", "log",
                 "track that i ate", "track a meal", "track", "i ate", "i had", "ate"]),
        (.todo, ["add a to-do to", "add a to-do", "add a todo to", "add a todo",
                 "add a task to", "add a task", "create a to-do", "create a task",
                 "new to-do", "new task", "remind me to", "remind me", "to-do", "todo"]),
    ]

    /// Returns the detected action and the payload text to act on. Never executes.
    func classify(_ transcript: String) -> (action: Action, payload: String) {
        let cleaned = Self.stripWakeWord(transcript)
        guard !cleaned.isEmpty else { return (.unknown, "") }
        let lower = cleaned.lowercased()

        // Signal-based detection for the trackers (parsers extract values from the full phrase).
        if lower.contains("pill") || lower.contains("medication") || lower.contains("medicine")
            || lower.contains("supplement") || lower.contains("vitamin") {
            return (.pill, cleaned)
        }
        if lower.contains("habit") {
            let creating = ["add", "create", "new", "start", "track"].contains { lower.contains($0) }
            return (creating ? .addHabit : .habit, cleaned)
        }
        if lower.contains("mood") || lower.contains("i feel") || lower.contains("feeling") { return (.mood, cleaned) }
        if lower.contains("water") || lower.contains("glass") || lower.contains("bottle") { return (.water, cleaned) }
        // Workout needs activity + duration cues; checked before "log …" is read as a meal.
        if Self.isWorkout(lower) { return (.workout, cleaned) }

        // Prefix-based detection for to-do / note / meal / completion.
        for (action, prefixes) in Self.prefixes {
            for prefix in prefixes.sorted(by: { $0.count > $1.count }) where lower.hasPrefix(prefix) {
                let start = cleaned.index(cleaned.startIndex, offsetBy: prefix.count)
                let payload = Self.trim(String(cleaned[start...]))
                return (action, payload.isEmpty ? cleaned : payload)
            }
        }

        // No keyword matched — assume it's a to-do.
        return (.todo, cleaned)
    }

    private static func isWorkout(_ lower: String) -> Bool {
        let hasWorkoutWord = ["workout", "exercise", "worked out", "work out", "gym"]
            .contains { lower.contains($0) }
        let hasActivity = VoiceParsing.activities.contains { lower.contains($0) }
        let hasDuration = lower.contains("minute") || lower.contains(" min")
        return hasWorkoutWord || (hasActivity && hasDuration) || (hasActivity && lower.hasPrefix("log"))
    }

    /// Classifies then performs the command, returning a spoken-style confirmation.
    func handle(_ transcript: String) async -> (action: Action, message: String) {
        let (action, payload) = classify(transcript)
        let actions = CommandActions()
        switch action {
        case .todo: return (action, await actions.addTodo(payload))
        case .note: return (action, await actions.addNote(payload))
        case .meal: return (action, await actions.logMeal(payload))
        case .complete: return (action, await actions.completeTodo(payload))
        case .water: return (action, await actions.logWater(payload))
        case .workout: return (action, await actions.logWorkout(payload))
        case .mood: return (action, await actions.logMood(payload))
        case .habit: return (action, await actions.completeHabit(payload))
        case .addHabit: return (action, await actions.addHabit(payload))
        case .pill: return (action, await actions.logPill(payload))
        case .unknown: return (action, "I didn't catch that. Try “Halo, add a to-do…”.")
        }
    }

    // MARK: - Helpers

    /// True if the utterance begins with a "Halo" wake word (for background listening).
    static func startsWithWakeWord(_ text: String) -> Bool {
        let lower = trim(text).lowercased()
        return wakeWords.contains { lower.hasPrefix($0) }
    }

    static func stripWakeWord(_ text: String) -> String {
        var result = trim(text)
        // Drop a leading "Halo" wake word (in-app path).
        let lower = result.lowercased()
        for word in wakeWords where lower.hasPrefix(word) {
            let start = result.index(result.startIndex, offsetBy: word.count)
            result = trim(String(result[start...]))
            break
        }
        // Drop a leading "that" connector (from "tell Halo that …").
        if result.lowercased().hasPrefix("that ") {
            result = trim(String(result.dropFirst(5)))
        }
        return result
    }

    private static func trim(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: " ,:;-.\u{2019}'"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation
import FoundationModels

/// On-device AI for Halo — intent understanding plus the generative helpers behind the AI features
/// (mood journaling, weekly insights, meal suggestions, briefing polish, note→to-dos, workout burn).
///
/// All `FoundationModels` use is isolated here. Every call is gated on
/// `SystemLanguageModel.default.availability` and wrapped in `try/catch`, returning `nil` so callers
/// fall back to deterministic logic when Apple Intelligence is unavailable (e.g. the simulator).
enum HaloIntelligence {

    private static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Runs the model for a free-form text response, or `nil` on unavailability/failure.
    private static func generateText(instructions: String, prompt: String) async -> String? {
        guard isAvailable else { return nil }
        do {
            let session = LanguageModelSession(instructions: instructions)
            let text = try await session.respond(to: prompt).content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }

    // MARK: - Multi-command understanding

    @Generable
    struct Command {
        @Guide(description: """
        One action. Must be exactly one of: todo (add a task/reminder), note (save a note), \
        meal (log food eaten), complete (mark a task done), water (log water), workout (log exercise), \
        mood (log how they feel), habit (mark a habit done), addHabit (create a new habit), \
        pill (log a medication/supplement taken), weight (log body weight), sleep (log hours slept), \
        pillSchedule (set up a recurring medication reminder, e.g. "remind me to take vitamin D at 9am every day"), \
        reflect (wrap up / reflect on the day), query (answer a question about their data), \
        briefing (summarize today), insights (summarize the week/trends), suggest (suggest a meal), \
        delete (remove an entry), edit (change an existing entry), extractTodos (turn a note into to-dos).
        """)
        var action: String

        @Guide(description: """
        The content for this action, with wake words ("Halo", "hey Siri", "tell Halo") and filler \
        removed. Keep the task and any time for a to-do; the food for a meal; the question for a query.
        """)
        var payload: String
    }

    @Generable
    struct Plan {
        @Guide(description: """
        One or more commands. Most sentences are a single command — only produce multiple when the \
        user clearly asks for several distinct actions (e.g. "log water and finish the dishes").
        """)
        var commands: [Command]
    }

    /// Splits a spoken sentence into one or more `(action, payload)` commands, or `nil` to fall back
    /// to the rule-based `VoiceCommandRouter.classify`.
    @MainActor
    static func plan(_ transcript: String) async -> [(action: VoiceCommandRouter.Action, payload: String)]? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isAvailable else { return nil }

        let instructions = """
        You route commands for Halo, a voice-first lifestyle app with eight trackers: to-dos, notes, \
        diet, habits, water, workouts, mood, and pills. Break the user's sentence into the distinct \
        actions it requests — usually just one. Prefer logging actions for statements about what the \
        user did or ate, and query/insights for questions. Respond only with the structured result.
        """
        do {
            let session = LanguageModelSession(instructions: instructions)
            let plan = try await session.respond(to: trimmed, generating: Plan.self).content
            let mapped: [(VoiceCommandRouter.Action, String)] = plan.commands.compactMap { command in
                guard let action = mapAction(command.action) else { return nil }
                let payload = command.payload.trimmingCharacters(in: .whitespacesAndNewlines)
                return (action, payload.isEmpty ? VoiceCommandRouter.stripWakeWord(trimmed) : payload)
            }
            return mapped.isEmpty ? nil : mapped
        } catch {
            return nil
        }
    }

    // MARK: - Mood journaling

    @Generable
    struct MoodReflection {
        @Guide(description: "Mood rating from 1 (awful) to 5 (great).")
        var rating: Int
        @Guide(description: "A short reflective note (a few words) capturing what they shared.")
        var note: String
        @Guide(description: "One brief, warm, supportive sentence in response.")
        var reply: String
    }

    @MainActor
    static func reflectMood(_ text: String) async -> (rating: Int, note: String, reply: String)? {
        guard isAvailable, !text.isEmpty else { return nil }
        let instructions = """
        You are a kind journaling assistant. From what the person says about their feelings, infer a \
        mood rating (1 awful – 5 great), write a short reflective note, and a single warm, supportive \
        sentence. Keep it gentle and non-clinical.
        """
        do {
            let session = LanguageModelSession(instructions: instructions)
            let result = try await session.respond(to: text, generating: MoodReflection.self).content
            return (min(max(result.rating, 1), 5),
                    result.note.trimmingCharacters(in: .whitespacesAndNewlines),
                    result.reply.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return nil
        }
    }

    // MARK: - Notes → to-dos

    @Generable
    struct TaskList {
        @Guide(description: "Actionable to-do items found in the note, each a short imperative phrase.")
        var tasks: [String]
    }

    @MainActor
    static func extractTasks(from note: String) async -> [String]? {
        guard isAvailable, !note.isEmpty else { return nil }
        let instructions = "Extract the actionable to-do items from the note. Ignore anything that isn't a task."
        do {
            let session = LanguageModelSession(instructions: instructions)
            let list = try await session.respond(to: note, generating: TaskList.self).content
            let tasks = list.tasks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            return tasks.isEmpty ? nil : tasks
        } catch {
            return nil
        }
    }

    // MARK: - Workout calorie burn

    @Generable
    struct WorkoutBurn {
        @Guide(description: "Estimated calories burned (kcal) for the workout.")
        var calories: Int
    }

    @MainActor
    static func estimateWorkoutKcal(type: String, minutes: Int) async -> Int? {
        guard isAvailable, minutes > 0 else { return nil }
        let instructions = "Estimate calories burned for a workout. Use typical values for an average adult."
        do {
            let session = LanguageModelSession(instructions: instructions)
            let burn = try await session.respond(
                to: "Estimate calories burned for \(minutes) minutes of \(type).",
                generating: WorkoutBurn.self
            ).content
            return burn.calories > 0 ? burn.calories : nil
        } catch {
            return nil
        }
    }

    // MARK: - Free-text helpers (numbers are supplied; the model only words them)

    @MainActor
    static func weeklyInsight(facts: String) async -> String? {
        await generateText(
            instructions: """
            You are a supportive health coach. Given a person's last-7-day stats, give one or two \
            short sentences of insight plus a single practical tip. Be encouraging and specific. Do \
            not invent numbers beyond those given.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func polishBriefing(facts: String) async -> String? {
        await generateText(
            instructions: """
            Rephrase today's stats into a warm, motivating one-paragraph recap ending with a short \
            actionable tip. Keep all numbers exactly as given; do not invent any.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func coachNudge(facts: String) async -> String? {
        await generateText(
            instructions: """
            You are an upbeat daily coach. From today's figures, write one short, motivating sentence \
            about where the day stands, then one concrete suggestion for the next best action. Keep \
            all numbers exactly as given; do not invent any.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func reflectDay(facts: String) async -> String? {
        await generateText(
            instructions: """
            You are a gentle end-of-day companion. From today's figures, write two or three warm, \
            reflective sentences celebrating what went well and noting one kind thing to try tomorrow. \
            Keep all numbers exactly as given; do not invent any. Be encouraging, never clinical.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func correlationInsight(facts: String) async -> String? {
        await generateText(
            instructions: """
            You are an insightful wellness coach. The facts list patterns already computed from the \
            person's data. Pick the single most interesting one and explain it warmly in one or two \
            sentences, then add a short encouraging suggestion. Do not invent numbers or patterns \
            beyond those given.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func sleepCoach(facts: String) async -> String? {
        await generateText(
            instructions: """
            You are a supportive sleep coach. From the person's recent sleep stats, write one or two \
            short sentences of insight plus one practical, actionable tip to sleep better (e.g. a \
            steadier bedtime, winding down earlier, fewer screens). Be warm and specific. Keep all \
            numbers exactly as given; do not invent any. Never give medical advice.
            """,
            prompt: facts
        )
    }

    @MainActor
    static func suggestMeals(remaining: Int, dietContext: String, request: String) async -> String? {
        // The diet profile is a hard constraint, so it lives in the instructions (which the model
        // honors far more strictly) rather than the user prompt.
        let dietLine = dietContext.isEmpty ? "" : "\n\nThe person's diet profile, which you must honor: \(dietContext)"
        return await generateText(
            instructions: """
            You are a nutrition assistant. Suggest two or three concrete meal ideas that fit within \
            the person's remaining calorie budget for today, with rough calorie counts. Keep it brief. \
            Strictly honor their stated diet (e.g. vegetarian, vegan, pescatarian) and lean toward the \
            foods they like. NEVER suggest a food they are allergic to or have said they dislike.\(dietLine)
            """,
            prompt: "Remaining budget: \(remaining) kcal.\(request.isEmpty ? "" : " They also asked: \(request)")"
        )
    }

    // MARK: - Action mapping

    /// Maps a model-produced action token to an `Action`, tolerating spacing/case. Returns `nil`
    /// for unrecognized or `unknown` tokens so the caller can fall back to rules.
    private static func mapAction(_ raw: String) -> VoiceCommandRouter.Action? {
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch token {
        case "addhabit", "add habit", "new habit": return .addHabit
        case "pillschedule", "pill schedule", "medication schedule", "schedule": return .pillSchedule
        case "reflect", "reflection", "wrap up": return .reflect
        case "todo", "to-do", "task": return .todo
        case "extracttodos", "extract todos", "extract", "extracttasks": return .extractTodos
        case "insight", "insights", "trends": return .insights
        case "suggestion", "suggestions": return .suggest
        default:
            guard let action = VoiceCommandRouter.Action(rawValue: token), action != .unknown else { return nil }
            return action
        }
    }
}

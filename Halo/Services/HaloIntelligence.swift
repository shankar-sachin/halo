import Foundation
import FoundationModels

/// On-device AI understanding for the in-app Halo (and Siri / background paths).
///
/// Uses Apple's `FoundationModels` to classify a free-form spoken sentence into one of Halo's
/// actions and extract the relevant payload — so natural phrasing ("I crushed a 5k this morning",
/// "what's left for dinner?") routes correctly. When Apple Intelligence is unavailable (e.g. the
/// simulator), `classify` returns `nil` and the caller falls back to the rule-based
/// `VoiceCommandRouter.classify`. Mirrors the on-device pattern in `CalorieEstimator`.
enum HaloIntelligence {

    /// Structured intent the on-device model is asked to produce.
    @Generable
    struct Understanding {
        @Guide(description: """
        The single best action for the user's sentence. Must be exactly one of: \
        todo (add a task/reminder), note (save a note), meal (log food eaten), \
        complete (mark a task done), water (log water), workout (log exercise), \
        mood (log how they feel), habit (mark a habit done), addHabit (create a new habit), \
        pill (log medication/supplement), query (answer a question about their data), \
        briefing (summarize their day), delete (remove an entry), edit (change an existing entry).
        """)
        var action: String

        @Guide(description: """
        The relevant content to act on, with wake words ("Halo", "hey Siri", "tell Halo") and \
        filler removed. For a to-do keep the task and any time; for a meal keep the food; for a \
        query keep what they're asking about. Echo the user's wording otherwise.
        """)
        var payload: String
    }

    /// Returns the AI-classified action + payload, or `nil` to fall back to rule-based routing.
    @MainActor
    static func classify(_ transcript: String) async -> (action: VoiceCommandRouter.Action, payload: String)? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard case .available = SystemLanguageModel.default.availability else { return nil }

        let instructions = """
        You route commands for Halo, a voice-first lifestyle app with eight trackers: to-dos, notes, \
        diet, habits, water, workouts, mood, and pills. Given one spoken sentence, pick the single \
        best action and extract its payload. Prefer logging actions for statements about what the \
        user did or ate, and the query action for questions. Respond only with the structured result.
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: trimmed, generating: Understanding.self)
            guard let action = mapAction(response.content.action) else { return nil }
            let payload = response.content.payload.trimmingCharacters(in: .whitespacesAndNewlines)
            return (action, payload.isEmpty ? VoiceCommandRouter.stripWakeWord(trimmed) : payload)
        } catch {
            return nil
        }
    }

    /// Maps a model-produced action token to an `Action`, tolerating spacing/case. Returns `nil`
    /// for unrecognized or `unknown` tokens so the caller can fall back to rules.
    private static func mapAction(_ raw: String) -> VoiceCommandRouter.Action? {
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch token {
        case "addhabit", "add habit", "new habit": return .addHabit
        case "todo", "to-do", "task": return .todo
        default:
            guard let action = VoiceCommandRouter.Action(rawValue: token), action != .unknown else { return nil }
            return action
        }
    }
}

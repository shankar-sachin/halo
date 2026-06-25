import AppIntents

/// A single pass-through intent: the whole spoken sentence is routed through `VoiceCommandRouter`,
/// so one phrase — "Hey Siri, tell Halo …" — handles to-dos, notes, meals, water, workouts,
/// mood, habits, and pills.
struct HaloCommandIntent: AppIntent {
    static let title: LocalizedStringResource = "Tell Halo"
    static let description = IntentDescription("Say any command and Halo figures out what to do.")
    static let openAppWhenRun = false

    @Parameter(title: "Command", requestValueDialog: "What would you like to tell Halo?")
    var command: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw $command.needsValueError("What would you like to tell Halo?")
        }
        let outcome = await VoiceCommandRouter().handle(text)
        return .result(dialog: IntentDialog(stringLiteral: outcome.message))
    }
}

import AppIntents
import SwiftData

struct CompleteTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a To-Do"
    static let description = IntentDescription("Marks a matching to-do as done, optionally at a spoken time.")
    static let openAppWhenRun = false

    @Parameter(title: "What did you finish?", requestValueDialog: "What did you finish?")
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $content.needsValueError("What did you finish?")
        }
        let message = await CommandActions().completeTodo(content)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

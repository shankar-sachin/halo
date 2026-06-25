import AppIntents
import SwiftData

struct SetTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a To-Do"
    static let description = IntentDescription("Creates a to-do, with an optional spoken due time.")
    static let openAppWhenRun = false

    @Parameter(title: "To-Do", requestValueDialog: "What's the to-do?")
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $content.needsValueError("What's the to-do?")
        }
        let message = await CommandActions().addTodo(content)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

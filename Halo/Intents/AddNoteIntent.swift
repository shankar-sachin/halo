import AppIntents
import SwiftData

struct AddNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Note"
    static let description = IntentDescription("Saves a spoken note in Halo.")
    static let openAppWhenRun = false

    @Parameter(title: "Note", requestValueDialog: "What would you like the note to say?")
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $content.needsValueError("What would you like the note to say?")
        }
        let message = await CommandActions().addNote(content)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

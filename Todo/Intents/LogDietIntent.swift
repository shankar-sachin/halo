import AppIntents
import SwiftData

struct LogDietIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Meal"
    static let description = IntentDescription("Estimates calories for a spoken meal and logs it.")
    static let openAppWhenRun = false

    @Parameter(title: "Food", requestValueDialog: "What did you eat?")
    var food: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !food.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $food.needsValueError("What did you eat?")
        }
        let message = await CommandActions().logMeal(food)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

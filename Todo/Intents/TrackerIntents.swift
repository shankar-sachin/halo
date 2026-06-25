import AppIntents

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description = IntentDescription("Logs water intake, e.g. a glass or 500 ml.")
    static let openAppWhenRun = false

    @Parameter(title: "Amount", requestValueDialog: "How much water? e.g. a glass")
    var amount: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $amount.needsValueError("How much water?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logWater(amount)))
    }
}

struct LogWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Workout"
    static let description = IntentDescription("Logs a workout, e.g. a 30 minute run.")
    static let openAppWhenRun = false

    @Parameter(title: "Workout", requestValueDialog: "What workout? e.g. a 30 minute run")
    var workout: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !workout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $workout.needsValueError("What workout did you do?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logWorkout(workout)))
    }
}

struct LogMoodIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Mood"
    static let description = IntentDescription("Logs how you're feeling.")
    static let openAppWhenRun = false

    @Parameter(title: "Mood", requestValueDialog: "How are you feeling?")
    var mood: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $mood.needsValueError("How are you feeling?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logMood(mood)))
    }
}

struct CompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a Habit"
    static let description = IntentDescription("Marks one of your habits done for today.")
    static let openAppWhenRun = false

    @Parameter(title: "Habit", requestValueDialog: "Which habit did you complete?")
    var habit: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !habit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $habit.needsValueError("Which habit?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().completeHabit(habit)))
    }
}

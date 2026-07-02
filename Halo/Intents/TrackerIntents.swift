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

struct LogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Logs your body weight, e.g. 80 kilos.")
    static let openAppWhenRun = false

    @Parameter(title: "Weight", requestValueDialog: "What's your weight? e.g. 80 kilos")
    var weight: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $weight.needsValueError("What's your weight?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logWeight(weight)))
    }
}

struct LogSleepIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Sleep"
    static let description = IntentDescription("Logs how long you slept, e.g. 7 hours.")
    static let openAppWhenRun = false

    @Parameter(title: "Sleep", requestValueDialog: "How long did you sleep? e.g. 7 hours")
    var sleep: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !sleep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $sleep.needsValueError("How long did you sleep?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logSleep(sleep)))
    }
}

struct LogPillIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Pill"
    static let description = IntentDescription("Logs a medication or supplement, e.g. vitamin D.")
    static let openAppWhenRun = false

    @Parameter(title: "Pill", requestValueDialog: "Which pill did you take?")
    var pill: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !pill.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $pill.needsValueError("Which pill did you take?")
        }
        return .result(dialog: IntentDialog(stringLiteral: await CommandActions().logPill(pill)))
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

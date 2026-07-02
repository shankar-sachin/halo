import AppIntents
import WidgetKit
import SwiftUI

/// Logs a glass of water from Control Center / Lock Screen. Runs in the widget process, so it writes
/// through `WidgetStore` rather than the app-only `CommandActions`.
struct QuickLogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Glass of Water"
    static let description = IntentDescription("Adds a glass of water to Halo.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        WidgetStore.logGlass()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Opens Halo (the "Talk to Halo" voice button is on the main screen).
struct OpenHaloIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Halo"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult { .result() }
}

/// A Control Center / Lock Screen button that logs a glass of water in one tap.
struct LogWaterControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.sachi.halo.control.water") {
            ControlWidgetButton(action: QuickLogWaterIntent()) {
                Label("Log Water", systemImage: "drop.fill")
            }
        }
        .displayName("Log a Glass of Water")
        .description("Adds a glass of water to Halo.")
    }
}

/// Marks the next incomplete habit done from Control Center / Lock Screen. Runs in the widget
/// process, so it writes through `WidgetStore` rather than the app-only `CommandActions`.
struct QuickCompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a Habit"
    static let description = IntentDescription("Marks your next habit done in Halo.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        WidgetStore.completeNextHabit()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// A Control Center / Lock Screen button that marks the next incomplete habit done in one tap.
struct CompleteHabitControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.sachi.halo.control.habit") {
            ControlWidgetButton(action: QuickCompleteHabitIntent()) {
                Label("Complete Habit", systemImage: "checkmark.seal.fill")
            }
        }
        .displayName("Complete a Habit")
        .description("Marks your next habit done in Halo.")
    }
}

/// Logs the next due medication as taken from Control Center / Lock Screen.
struct QuickMarkPillTakenIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Pill Taken"
    static let description = IntentDescription("Logs your next scheduled medication in Halo.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        WidgetStore.markMedicationTaken()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// A Control Center / Lock Screen button that logs the next due medication in one tap.
struct MarkPillTakenControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.sachi.halo.control.pill") {
            ControlWidgetButton(action: QuickMarkPillTakenIntent()) {
                Label("Mark Pill Taken", systemImage: "pills.fill")
            }
        }
        .displayName("Mark Pill Taken")
        .description("Logs your next scheduled medication in Halo.")
    }
}

/// A Control Center button that opens Halo to talk to the assistant.
struct TalkToHaloControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.sachi.halo.control.talk") {
            ControlWidgetButton(action: OpenHaloIntent()) {
                Label("Talk to Halo", systemImage: "mic.fill")
            }
        }
        .displayName("Talk to Halo")
        .description("Opens Halo so you can speak a command.")
    }
}

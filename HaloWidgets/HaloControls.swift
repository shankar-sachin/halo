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

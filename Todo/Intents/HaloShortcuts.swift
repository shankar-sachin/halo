import AppIntents

/// One unified Siri entry: "Hey Siri, tell Halo". Siri then asks "What would you like to tell
/// Halo?" and the spoken sentence is routed by `VoiceCommandRouter`, so every feature works
/// through the same phrasing.
///
/// Note: Apple only allows `AppEntity`/`AppEnum` parameters inside App Shortcut phrases — a free-form
/// `String` can't be captured inline, so the command is gathered in Siri's follow-up question.
/// (The in-app and background "Halo, …" modes do capture the whole sentence in one breath.)
struct HaloShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HaloCommandIntent(),
            phrases: [
                "Tell \(.applicationName)",
                "Talk to \(.applicationName)",
                "Ask \(.applicationName)",
                "Give \(.applicationName) a command",
            ],
            shortTitle: "Tell Halo",
            systemImageName: "mic.fill"
        )
    }
}

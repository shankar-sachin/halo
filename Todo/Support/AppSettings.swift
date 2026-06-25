import Foundation

/// Shared App Group used by the app and the widget extension.
enum AppGroup {
    static let identifier = "group.com.sachi.halo"
}

extension UserDefaults {
    /// Preferences shared between the app and its widgets.
    /// `UserDefaults` is documented as thread-safe.
    nonisolated(unsafe) static let shared = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
}

/// Centralised keys + defaults for user preferences stored in `UserDefaults`/`@AppStorage`.
enum SettingsKey {
    static let dailyCalorieBudget = "dailyCalorieBudget"
    static let syncToHealth = "syncToHealth"
    static let waterGoalML = "waterGoalML"
    static let listenInBackground = "listenInBackground"
    static let hasOnboarded = "hasOnboarded"
}

enum SettingsDefault {
    static let dailyCalorieBudget = 2000
    static let syncToHealth = false
    static let waterGoalML = 2000
    static let listenInBackground = false

    /// Registers defaults so non-UI code (App Intents, services) reads sensible values.
    static func register() {
        UserDefaults.shared.register(defaults: [
            SettingsKey.dailyCalorieBudget: dailyCalorieBudget,
            SettingsKey.syncToHealth: syncToHealth,
            SettingsKey.waterGoalML: waterGoalML,
            SettingsKey.listenInBackground: listenInBackground,
        ])
    }

    static var budget: Int {
        let stored = UserDefaults.shared.integer(forKey: SettingsKey.dailyCalorieBudget)
        return stored == 0 ? dailyCalorieBudget : stored
    }

    static var waterGoal: Int {
        let stored = UserDefaults.shared.integer(forKey: SettingsKey.waterGoalML)
        return stored == 0 ? waterGoalML : stored
    }
}

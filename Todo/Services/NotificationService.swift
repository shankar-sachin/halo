import Foundation
import UserNotifications

/// Wraps local notifications: calorie-budget feedback after a meal, and to-do reminders.
struct NotificationService: Sendable {
    static let shared = NotificationService()

    private var center: UNUserNotificationCenter { .current() }

    /// Requests authorization if not yet determined. Safe to call repeatedly.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    /// Fires a budget/treat notification a moment after a meal is logged.
    func notifyMealLogged(consumed: Int, budget: Int) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let message = TreatSuggester().message(consumed: consumed, budget: budget)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Confirms a hands-free voice command performed while the app was backgrounded.
    func notifyVoiceResult(_ message: String) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Halo"
        content.body = message
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    /// Schedules a reminder for a to-do's due date (no-op if the date is in the past).
    func scheduleReminder(id: String, title: String, at date: Date) async {
        guard date > .now, await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}

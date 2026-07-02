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

    func cancelReminders(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Stable identifier for the single daily proactive-coach reminder.
    static let coachReminderID = "halo-daily-coach"

    /// Turns the daily coach briefing reminder on at the given hour (or off).
    func scheduleDailyCoach(hour: Int) async {
        await scheduleDailyReminder(
            id: Self.coachReminderID,
            title: "Your Halo briefing",
            body: "Open Halo to see how your day's shaping up — and plan your next move.",
            hour: hour, minute: 0
        )
    }

    func cancelDailyCoach() {
        cancelReminder(id: Self.coachReminderID)
    }

    /// Stable identifier for the first-of-the-month digest reminder.
    static let monthlyDigestID = "halo-monthly-digest"

    /// Turns the monthly digest reminder on (fires the 1st of each month at 9 AM) or off.
    func scheduleMonthlyDigest() async {
        guard await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your month with Halo"
        content.body = "Open Insights to review last month — what improved, and what to focus on next."
        content.sound = .default

        var components = DateComponents()
        components.day = 1
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: Self.monthlyDigestID, content: content, trigger: trigger))
    }

    func cancelMonthlyDigest() {
        cancelReminder(id: Self.monthlyDigestID)
    }

    /// Schedules a daily-repeating reminder at the given hour/minute (used for medication schedules
    /// and the proactive coach).
    func scheduleDailyReminder(id: String, title: String, body: String, hour: Int, minute: Int) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

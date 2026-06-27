import Foundation

/// Parses spoken time expressions like "by 5:30 pm today", "at 5:15 pm", or "tomorrow 9am"
/// into concrete `Date`s, and strips that phrasing out of a to-do title.
struct DateTimeParser {
    let calendar: Calendar
    private let detector: NSDataDetector?

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }

    /// Extracts the first date/time mentioned in `text`, relative to `referenceDate`.
    func parseDate(from text: String, referenceDate: Date = .now) -> Date? {
        guard let detector else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = detector.matches(in: text, range: range).first
        return match?.date
            .map { adjust($0, text: text, referenceDate: referenceDate) }
    }

    /// Returns the title with any trailing time expression removed,
    /// e.g. "eat yogurt by 5:30 pm today" -> "eat yogurt".
    func strippedTitle(from text: String) -> String {
        guard let detector else { return clean(text) }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = detector.matches(in: text, range: range).first,
              let matchRange = Range(match.range, in: text) else {
            return clean(text)
        }
        var result = text
        result.removeSubrange(matchRange)
        // Drop trailing connector words left behind ("by", "at", "due").
        let connectors: Set<String> = ["by", "at", "due", "on", "before", "around"]
        var words = result.split(separator: " ").map(String.init)
        while let last = words.last, connectors.contains(last.lowercased()) {
            words.removeLast()
        }
        return clean(words.joined(separator: " "))
    }

    /// Resolves a past day/week reference ("yesterday", "on Tuesday", "3 days ago", "last week") to a
    /// half-open date interval plus a spoken label. Returns nil when no past reference is present.
    func pastInterval(from text: String, referenceDate: Date = .now) -> (start: Date, end: Date, label: String)? {
        let lower = text.lowercased()
        let startOfToday = calendar.startOfDay(for: referenceDate)

        func dayInterval(_ day: Date, _ label: String) -> (Date, Date, String) {
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end, label)
        }

        if lower.contains("yesterday"), let y = calendar.date(byAdding: .day, value: -1, to: startOfToday) {
            return dayInterval(y, "yesterday")
        }
        if lower.contains("last week"), let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) {
            return (weekAgo, startOfToday, "in the last week")
        }
        if lower.contains("this week"),
           let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday),
           let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) {
            return (weekAgo, tomorrow, "this week")
        }
        if let n = daysAgo(in: lower), let day = calendar.date(byAdding: .day, value: -n, to: startOfToday) {
            return dayInterval(day, n == 1 ? "yesterday" : "\(n) days ago")
        }
        let weekdays = ["sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
                        "thursday": 5, "friday": 6, "saturday": 7]
        for (name, weekday) in weekdays where lower.contains(name) {
            if let day = mostRecentWeekday(weekday, onOrBefore: startOfToday) {
                return dayInterval(day, "on \(name.capitalized)")
            }
        }
        return nil
    }

    private func daysAgo(in lower: String) -> Int? {
        guard let range = lower.range(of: #"(\d+)\s+days?\s+ago"#, options: .regularExpression) else { return nil }
        let digits = lower[range].prefix { $0.isNumber }
        return Int(digits)
    }

    /// The most recent date with the given weekday at or before `reference` (excluding today itself,
    /// so "on Monday" asked on a Monday means last Monday).
    private func mostRecentWeekday(_ weekday: Int, onOrBefore reference: Date) -> Date? {
        for offset in 1...7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: reference) else { continue }
            if calendar.component(.weekday, from: day) == weekday { return day }
        }
        return nil
    }

    // MARK: - Helpers

    /// NSDataDetector resolves bare times to *today*; if that time has already passed and the
    /// text doesn't say "today", roll forward to tomorrow so reminders make sense.
    private func adjust(_ date: Date, text: String, referenceDate: Date) -> Date {
        let lower = text.lowercased()
        let mentionsDay = lower.contains("today") || lower.contains("tomorrow")
            || lower.contains("tonight") || lower.range(of: #"\d{1,2}/\d{1,2}"#, options: .regularExpression) != nil
        if !mentionsDay, date < referenceDate, calendar.isDate(date, inSameDayAs: referenceDate) {
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }

    private func clean(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: " ,.:;-"))
            .trimmingCharacters(in: .whitespaces)
    }
}

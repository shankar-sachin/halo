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

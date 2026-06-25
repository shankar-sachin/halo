import Foundation

/// Pure helpers that extract structured values from spoken phrases for the new trackers.
enum VoiceParsing {
    static let activities = ["running", "run", "ran", "jog", "jogging", "walk", "walking",
                             "cycling", "cycle", "bike", "biking", "swim", "swimming",
                             "yoga", "lift", "lifting", "weights", "strength", "hike", "hiking",
                             "cardio", "pilates", "rowing"]

    /// Milliliters of water from phrases like "a glass", "two bottles", "500 ml", "a litre".
    static func waterML(from text: String) -> Int {
        let lower = text.lowercased()
        // Explicit ml/liter amounts.
        if let ml = firstNumber(in: lower, near: ["ml", "milliliter", "millilitre"]) { return ml }
        if let liters = firstNumber(in: lower, near: ["liter", "litre", "l "]) { return liters * 1000 }

        let count = leadingCount(in: lower)
        if lower.contains("bottle") { return count * 500 }
        if lower.contains("glass") || lower.contains("cup") { return count * WaterEntry.glassML }
        // Default: one glass.
        return WaterEntry.glassML
    }

    /// Workout type + duration from phrases like "a 30 minute run".
    static func workout(from text: String) -> (type: String, minutes: Int) {
        let lower = text.lowercased()
        let minutes = firstNumber(in: lower, near: ["minute", "min"]) ?? anyNumber(in: lower) ?? 30
        let type = activities.first(where: { lower.contains($0) }).map(normalizeActivity) ?? "Workout"
        return (type, max(minutes, 1))
    }

    /// Cleans a habit phrase down to the likely habit name (for matching an existing habit).
    static func habitSearchText(from text: String) -> String {
        var words = text.lowercased().split(separator: " ").map(String.init)
        let drop: Set<String> = ["mark", "complete", "completed", "finish", "finished", "did",
                                  "do", "my", "the", "habit", "as", "done", "i", "a"]
        words.removeAll { drop.contains($0) }
        return words.joined(separator: " ")
    }

    /// Splits a pill phrase into (name, purpose).
    /// "I ate my digestion pill" → ("Digestion Pill", ""); "I took vitamin D for immunity" → ("Vitamin D", "immunity").
    static func pill(from text: String) -> (name: String, purpose: String) {
        var t = text.lowercased().trimmingCharacters(in: .whitespaces)
        let leads = ["i ate my", "i took my", "i had my", "i take my", "i ate", "i took", "i had",
                     "took my", "ate my", "take my", "log my", "took", "ate", "take", "log", "my"]
        for lead in leads.sorted(by: { $0.count > $1.count }) where t.hasPrefix(lead) {
            t = String(t.dropFirst(lead.count)).trimmingCharacters(in: .whitespaces)
            break
        }

        var name = t
        var purpose = ""
        if let range = t.range(of: " for ") {
            name = String(t[..<range.lowerBound])
            purpose = String(t[range.upperBound...])
        }
        name = name.trimmingCharacters(in: .whitespaces)
        purpose = purpose.trimmingCharacters(in: .whitespaces)
        return (name.capitalized, purpose)
    }

    /// Extracts a new habit's name from "add a habit to meditate" → "meditate".
    static func habitName(from text: String) -> String {
        var words = text.lowercased().split(separator: " ").map(String.init)
        let drop: Set<String> = ["add", "create", "new", "start", "track", "a", "an", "the",
                                  "habit", "to", "of", "my", "called", "for"]
        words.removeAll { drop.contains($0) }
        return words.joined(separator: " ")
    }

    private static func normalizeActivity(_ word: String) -> String {
        switch word {
        case "run", "running", "ran": "Run"
        case "jog", "jogging": "Jog"
        case "walk", "walking": "Walk"
        case "cycle", "cycling", "bike", "biking": "Cycling"
        case "swim", "swimming": "Swim"
        case "lift", "lifting", "weights", "strength": "Strength"
        case "hike", "hiking": "Hike"
        default: word.capitalized
        }
    }

    /// Count at the start of the phrase ("two glasses"), defaulting to 1.
    private static func leadingCount(in text: String) -> Int {
        let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6]
        for (word, value) in words where text.contains(word) { return value }
        if let n = anyNumber(in: text) { return n }
        return 1
    }

    /// First integer appearing just before any of the given units.
    private static func firstNumber(in text: String, near units: [String]) -> Int? {
        for unit in units {
            guard let unitRange = text.range(of: unit) else { continue }
            let prefix = text[text.startIndex..<unitRange.lowerBound]
            let digits = prefix.reversed().prefix { $0.isNumber || $0 == " " }
            let number = String(digits.reversed()).trimmingCharacters(in: .whitespaces)
            if let value = Int(number) { return value }
        }
        return nil
    }

    /// Any integer in the text.
    private static func anyNumber(in text: String) -> Int? {
        let digits = text.split { !$0.isNumber }.first.map(String.init)
        return digits.flatMap(Int.init)
    }
}

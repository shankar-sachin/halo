import Foundation
import SwiftData

@Model
final class MoodEntry {
    /// 1 (awful) … 5 (great).
    var rating: Int
    /// A short caption shown in the timeline.
    var note: String
    /// Optional long-form journal entry paired with this mood check-in.
    var journal: String = ""
    var loggedAt: Date

    init(rating: Int, note: String = "", journal: String = "", loggedAt: Date = .now) {
        self.rating = rating
        self.note = note
        self.journal = journal
        self.loggedAt = loggedAt
    }

    var emoji: String { MoodEntry.emoji(for: rating) }
    var label: String { MoodEntry.label(for: rating) }

    static func emoji(for rating: Int) -> String {
        switch rating {
        case ...1: "😞"
        case 2: "🙁"
        case 3: "😐"
        case 4: "🙂"
        default: "😄"
        }
    }

    static func label(for rating: Int) -> String {
        switch rating {
        case ...1: "Awful"
        case 2: "Low"
        case 3: "Okay"
        case 4: "Good"
        default: "Great"
        }
    }

    /// Maps a spoken mood word to a 1–5 rating.
    static func rating(from text: String) -> Int? {
        let t = text.lowercased()
        if t.contains("great") || t.contains("amazing") || t.contains("awesome") || t.contains("fantastic") { return 5 }
        if t.contains("good") || t.contains("happy") || t.contains("nice") { return 4 }
        if t.contains("okay") || t.contains("ok") || t.contains("fine") || t.contains("meh") || t.contains("neutral") { return 3 }
        if t.contains("low") || t.contains("sad") || t.contains("down") || t.contains("tired") { return 2 }
        if t.contains("awful") || t.contains("terrible") || t.contains("bad") || t.contains("horrible") { return 1 }
        return nil
    }
}

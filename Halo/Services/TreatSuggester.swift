import Foundation

/// Builds the friendly "you have room for…" message based on remaining calorie budget.
struct TreatSuggester {
    struct Treat {
        let name: String
        let calories: Int
        let emoji: String
    }

    static let treats: [Treat] = [
        .init(name: "a square of dark chocolate", calories: 50, emoji: "🍫"),
        .init(name: "an apple", calories: 95, emoji: "🍎"),
        .init(name: "a granola bar", calories: 120, emoji: "🥣"),
        .init(name: "a scoop of ice cream", calories: 137, emoji: "🍨"),
        .init(name: "a chocolate bar", calories: 230, emoji: "🍫"),
        .init(name: "a latte and a cookie", calories: 350, emoji: "☕️"),
        .init(name: "a slice of pizza", calories: 285, emoji: "🍕"),
    ]

    /// Returns title + body for a post-meal notification given today's totals.
    func message(consumed: Int, budget: Int) -> (title: String, body: String) {
        let remaining = budget - consumed

        if remaining <= 0 {
            let over = -remaining
            return (
                "Daily budget reached",
                "You've had \(consumed) kcal today — \(over) over your \(budget) kcal goal. Maybe wrap up for the day. 🌙"
            )
        }

        // Pick the most indulgent treat that still fits the remaining budget.
        let affordable = TreatSuggester.treats
            .filter { $0.calories <= remaining }
            .max(by: { $0.calories < $1.calories })

        let title = "\(consumed) kcal so far today"
        if let treat = affordable {
            return (
                title,
                "\(remaining) kcal left — enough room for \(treat.name) (~\(treat.calories) kcal) \(treat.emoji)"
            )
        }
        return (
            title,
            "\(remaining) kcal left for today — keep it light. 🥗"
        )
    }
}

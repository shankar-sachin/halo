import Foundation

/// Offline fallback that maps a spoken food phrase to an approximate calorie count
/// using a bundled table of common foods. Used when the on-device model is unavailable.
struct FoodDatabase {
    struct Food: Decodable {
        let name: String
        let serving: String
        let calories: Int
        let aliases: [String]
    }

    let foods: [Food]

    static let shared = FoodDatabase()

    init(foods: [Food]? = nil) {
        if let foods {
            self.foods = foods
            return
        }
        guard
            let url = Bundle.main.url(forResource: "foods", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Food].self, from: data)
        else {
            self.foods = []
            return
        }
        self.foods = decoded
    }

    /// Returns the best matching food for a free-form phrase, or `nil` if nothing matches.
    func match(_ phrase: String) -> Food? {
        let normalized = FoodDatabase.normalize(phrase)
        guard !normalized.isEmpty else { return nil }

        var best: (food: Food, score: Int)?
        for food in foods {
            let candidates = [food.name] + food.aliases
            for candidate in candidates {
                let key = FoodDatabase.normalize(candidate)
                guard !key.isEmpty else { continue }
                let score: Int
                if normalized == key {
                    score = 1000 + key.count
                } else if normalized.contains(key) {
                    // Prefer longer (more specific) matches, e.g. "brown rice" over "rice".
                    score = 500 + key.count
                } else {
                    continue
                }
                if best == nil || score > best!.score {
                    best = (food, score)
                }
            }
        }
        return best?.food
    }

    static func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
}

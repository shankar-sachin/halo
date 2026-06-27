import Foundation

/// Deterministic, diet-aware meal suggestions — the fallback when Apple Intelligence is unavailable
/// (e.g. the simulator). Respects the user's `DietType` and filters out their allergens, so a
/// vegetarian never gets "chicken salad." Pure and unit-tested.
enum MealSuggester {
    private struct Meal {
        let name: String
        let kcal: Int
        let diets: Set<DietType>
        let allergens: Set<String>   // lowercase tags, matched loosely against the user's list
    }

    private static let catalog: [Meal] = [
        Meal(name: "a greek yogurt with berries", kcal: 150, diets: [.vegetarian, .pescatarian, .omnivore], allergens: ["dairy"]),
        Meal(name: "hummus with veg sticks", kcal: 180, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: ["sesame"]),
        Meal(name: "a boiled egg and fruit", kcal: 200, diets: [.vegetarian, .pescatarian, .omnivore], allergens: ["eggs"]),
        Meal(name: "a chickpea salad", kcal: 350, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: []),
        Meal(name: "a tuna salad", kcal: 350, diets: [.pescatarian, .omnivore], allergens: ["fish"]),
        Meal(name: "a tofu stir-fry", kcal: 400, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: ["soy"]),
        Meal(name: "a chicken salad", kcal: 400, diets: [.omnivore], allergens: []),
        Meal(name: "a veggie wrap", kcal: 450, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: ["gluten"]),
        Meal(name: "a paneer bowl", kcal: 450, diets: [.vegetarian, .pescatarian, .omnivore], allergens: ["dairy"]),
        Meal(name: "a lentil curry with rice", kcal: 500, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: []),
        Meal(name: "a salmon bowl", kcal: 550, diets: [.pescatarian, .omnivore], allergens: ["fish"]),
        Meal(name: "pasta with veg", kcal: 600, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: ["gluten"]),
        Meal(name: "a veg burrito", kcal: 600, diets: [.vegan, .vegetarian, .pescatarian, .omnivore], allergens: ["gluten"]),
    ]

    /// A spoken-style suggestion string fitting `remaining` kcal, the diet, and avoiding allergens.
    static func suggestion(dietType: DietType, allergies: String, remaining: Int) -> String {
        if remaining <= 0 {
            return "You're at your budget for today — maybe a light option like herbal tea or some veg sticks. 🥕"
        }
        let blocked = DietPreferences.tokens(allergies).map { $0.lowercased() }
        let fitting = catalog
            .filter { $0.diets.contains(dietType) }
            .filter { meal in !meal.allergens.contains { tag in blocked.contains { $0.contains(tag) || tag.contains($0) } } }
            .filter { $0.kcal <= remaining }
            .sorted { $0.kcal > $1.kcal }

        guard !fitting.isEmpty else {
            return "About \(remaining) kcal left — a small fruit or some veg sticks would fit."
        }
        // Up to three substantial options that fit.
        let picks = Array(fitting.prefix(3))
        let phrases = picks.map { "\($0.name) (~\($0.kcal))" }
        let list: String
        switch phrases.count {
        case 1: list = phrases[0]
        case 2: list = "\(phrases[0]) or \(phrases[1])"
        default: list = "\(phrases[0]), \(phrases[1]), or \(phrases[2])"
        }
        return "About \(remaining) kcal left — \(list) would fit."
    }
}

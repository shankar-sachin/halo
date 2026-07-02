import Foundation
import SwiftData

enum CalorieSource: String, Codable {
    case ai
    case table
    case manual
}

/// What kind of intake a diet entry is. Caffeine/alcohol are still diet entries — same calories,
/// same daily budget — just tagged so they can be badged and filtered.
enum DietCategory: String, Codable, CaseIterable, Identifiable {
    case food, caffeine, alcohol

    var id: String { rawValue }

    var label: String {
        switch self {
        case .food: "Food"
        case .caffeine: "Caffeine"
        case .alcohol: "Alcohol"
        }
    }

    var symbol: String {
        switch self {
        case .food: "fork.knife.circle.fill"
        case .caffeine: "cup.and.saucer.fill"
        case .alcohol: "wineglass.fill"
        }
    }

    /// Deterministic keyword inference for voice-logged entries (no AI classification needed).
    static func inferred(from foodText: String) -> DietCategory {
        let lower = foodText.lowercased()
        let caffeineWords = ["coffee", "espresso", "latte", "cappuccino", "americano", "macchiato",
                             "cold brew", "energy drink", "red bull", "matcha", "chai"]
        if caffeineWords.contains(where: { lower.contains($0) }) { return .caffeine }
        let alcoholWords = ["beer", "wine", "whiskey", "whisky", "vodka", "rum", "gin", "tequila",
                            "cocktail", "margarita", "sake", "cider", "champagne", "prosecco"]
        if alcoholWords.contains(where: { lower.contains($0) }) { return .alcohol }
        return .food
    }
}

@Model
final class DietEntry {
    var foodText: String
    var calories: Int
    var loggedAt: Date
    var sourceRaw: String
    /// Estimated macronutrients in grams (0 when unknown, e.g. table/manual entries).
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var categoryRaw: String = DietCategory.food.rawValue

    init(
        foodText: String,
        calories: Int,
        loggedAt: Date = .now,
        source: CalorieSource = .manual,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0,
        category: DietCategory = .food
    ) {
        self.foodText = foodText
        self.calories = calories
        self.loggedAt = loggedAt
        self.sourceRaw = source.rawValue
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.categoryRaw = category.rawValue
    }

    /// True when the model produced macro estimates worth displaying.
    var hasMacros: Bool { protein > 0 || carbs > 0 || fat > 0 }

    var source: CalorieSource {
        get { CalorieSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var category: DietCategory {
        get { DietCategory(rawValue: categoryRaw) ?? .food }
        set { categoryRaw = newValue.rawValue }
    }
}

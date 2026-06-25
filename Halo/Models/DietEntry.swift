import Foundation
import SwiftData

enum CalorieSource: String, Codable {
    case ai
    case table
    case manual
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

    init(
        foodText: String,
        calories: Int,
        loggedAt: Date = .now,
        source: CalorieSource = .manual,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0
    ) {
        self.foodText = foodText
        self.calories = calories
        self.loggedAt = loggedAt
        self.sourceRaw = source.rawValue
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    /// True when the model produced macro estimates worth displaying.
    var hasMacros: Bool { protein > 0 || carbs > 0 || fat > 0 }

    var source: CalorieSource {
        get { CalorieSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

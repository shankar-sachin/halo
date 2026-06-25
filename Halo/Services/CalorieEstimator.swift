import Foundation
import FoundationModels

/// Estimates calories from a free-form spoken food description.
///
/// Prefers Apple's on-device foundation model (`FoundationModels`) for flexible, offline
/// estimation; falls back to the bundled `FoodDatabase` when Apple Intelligence is unavailable
/// (e.g. the simulator or a non-eligible device).
struct CalorieEstimator {

    /// Structured output the on-device model is asked to produce.
    @Generable
    struct ModelEstimate {
        @Guide(description: "A short canonical name of the food and its serving, e.g. '1 cup greek yogurt'.")
        var food: String
        @Guide(description: "Estimated total calories (kcal) for the described amount.")
        var calories: Int
        @Guide(description: "Estimated protein in grams for the described amount.")
        var protein: Int
        @Guide(description: "Estimated carbohydrates in grams for the described amount.")
        var carbs: Int
        @Guide(description: "Estimated fat in grams for the described amount.")
        var fat: Int
    }

    static let shared = CalorieEstimator()

    private let database: FoodDatabase

    init(database: FoodDatabase = .shared) {
        self.database = database
    }

    /// Returns a best-effort calorie estimate. Never throws — falls back gracefully.
    func estimate(for phrase: String) async -> CalorieEstimate {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CalorieEstimate(foodText: phrase, calories: 0, source: .manual)
        }

        if case .available = SystemLanguageModel.default.availability,
           let aiEstimate = await modelEstimate(for: trimmed) {
            return aiEstimate
        }
        return tableEstimate(for: trimmed)
    }

    // MARK: - On-device model

    private func modelEstimate(for phrase: String) async -> CalorieEstimate? {
        let instructions = """
        You are a nutrition assistant. Given a description of food a person ate, estimate the \
        total calories and the macronutrients (protein, carbohydrates, fat) in grams for the \
        amount described. Use typical average values. If no amount is given, assume one standard \
        serving. Respond only with the structured result.
        """
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: "Estimate calories for: \(phrase)",
                generating: ModelEstimate.self
            )
            let result = response.content
            let calories = max(result.calories, 0)
            guard calories > 0 else { return nil }
            return CalorieEstimate(
                foodText: phrase,
                calories: calories,
                source: .ai,
                protein: max(result.protein, 0),
                carbs: max(result.carbs, 0),
                fat: max(result.fat, 0)
            )
        } catch {
            return nil
        }
    }

    // MARK: - Offline fallback

    private func tableEstimate(for phrase: String) -> CalorieEstimate {
        if let food = database.match(phrase) {
            return CalorieEstimate(foodText: phrase, calories: food.calories, source: .table)
        }
        // Unknown food: log it with 0 calories so the user can correct it manually.
        return CalorieEstimate(foodText: phrase, calories: 0, source: .table)
    }
}

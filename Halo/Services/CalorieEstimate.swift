import Foundation

/// Unified result returned by `CalorieEstimator`, regardless of which backend produced it.
struct CalorieEstimate {
    var foodText: String
    var calories: Int
    var source: CalorieSource
    /// Estimated macronutrients in grams (0 when the backend can't provide them).
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0

    var isConfident: Bool { calories > 0 }
    var hasMacros: Bool { protein > 0 || carbs > 0 || fat > 0 }
}

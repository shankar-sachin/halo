import Foundation

/// Unified result returned by `CalorieEstimator`, regardless of which backend produced it.
struct CalorieEstimate {
    var foodText: String
    var calories: Int
    var source: CalorieSource

    var isConfident: Bool { calories > 0 }
}

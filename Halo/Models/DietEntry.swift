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

    init(
        foodText: String,
        calories: Int,
        loggedAt: Date = .now,
        source: CalorieSource = .manual
    ) {
        self.foodText = foodText
        self.calories = calories
        self.loggedAt = loggedAt
        self.sourceRaw = source.rawValue
    }

    var source: CalorieSource {
        get { CalorieSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

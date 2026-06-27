import Foundation

/// The user's overall eating style.
enum DietType: String, CaseIterable, Identifiable {
    case omnivore, vegetarian, vegan, pescatarian

    var id: String { rawValue }

    var label: String {
        switch self {
        case .omnivore: "Omnivore"
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .pescatarian: "Pescatarian"
        }
    }

    var icon: String {
        switch self {
        case .omnivore: "fork.knife"
        case .vegetarian: "carrot.fill"
        case .vegan: "leaf.fill"
        case .pescatarian: "fish.fill"
        }
    }

    /// How the model should describe the constraint when suggesting meals.
    var dietaryRule: String {
        switch self {
        case .omnivore: "no dietary restriction"
        case .vegetarian: "vegetarian (no meat or fish)"
        case .vegan: "vegan (no animal products)"
        case .pescatarian: "pescatarian (fish but no other meat)"
        }
    }
}

/// Shared diet preferences, stored in the App Group `UserDefaults`. Read by the AI meal suggestions
/// and edited from both onboarding and Settings.
enum DietPreferences {
    /// Common allergens offered as quick toggles; the user can also type their own.
    static let commonAllergens = ["Peanuts", "Tree nuts", "Dairy", "Eggs", "Gluten", "Shellfish", "Soy", "Fish", "Sesame"]

    static var type: DietType {
        get { DietType(rawValue: UserDefaults.shared.string(forKey: SettingsKey.dietType) ?? "") ?? .omnivore }
        set { UserDefaults.shared.set(newValue.rawValue, forKey: SettingsKey.dietType) }
    }

    static var likes: String { UserDefaults.shared.string(forKey: SettingsKey.dietLikes) ?? "" }
    static var avoid: String { UserDefaults.shared.string(forKey: SettingsKey.dietAvoid) ?? "" }
    static var allergies: String { UserDefaults.shared.string(forKey: SettingsKey.dietAllergies) ?? "" }

    // MARK: - Comma-separated token helpers (for the allergen chips)

    static func tokens(_ string: String) -> [String] {
        string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    static func contains(_ string: String, _ token: String) -> Bool {
        tokens(string).contains { $0.caseInsensitiveCompare(token) == .orderedSame }
    }

    /// Returns the comma-separated string with `token` added or removed.
    static func toggling(_ string: String, _ token: String) -> String {
        var items = tokens(string)
        if let index = items.firstIndex(where: { $0.caseInsensitiveCompare(token) == .orderedSame }) {
            items.remove(at: index)
        } else {
            items.append(token)
        }
        return items.joined(separator: ", ")
    }

    /// A compact summary for the AI meal-suggestion prompt, or empty when nothing is set.
    static var aiContext: String {
        var parts = ["Diet: \(type.dietaryRule)."]
        let likes = likes.trimmingCharacters(in: .whitespacesAndNewlines)
        let avoid = avoid.trimmingCharacters(in: .whitespacesAndNewlines)
        let allergies = allergies.trimmingCharacters(in: .whitespacesAndNewlines)
        if !likes.isEmpty { parts.append("Likes: \(likes).") }
        if !avoid.isEmpty { parts.append("Dislikes: \(avoid).") }
        if !allergies.isEmpty { parts.append("Allergic to: \(allergies). Never suggest these.") }
        return parts.joined(separator: " ")
    }
}

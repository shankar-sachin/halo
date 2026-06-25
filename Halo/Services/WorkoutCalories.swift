import Foundation

/// Deterministic calorie-burn estimate for a workout, used as the offline/simulator fallback when
/// the on-device AI model (`HaloIntelligence.estimateWorkoutKcal`) is unavailable.
///
/// Uses the standard MET formula: `kcal ≈ MET × 3.5 × weightKg / 200 × minutes`.
enum WorkoutCalories {

    /// Approximate MET (metabolic equivalent) for the normalized workout types produced by
    /// `VoiceParsing.workout` (and any free-form type), matched case-insensitively by keyword.
    private static func met(for type: String) -> Double {
        let t = type.lowercased()
        if t.contains("run") { return 9.8 }
        if t.contains("jog") { return 7.0 }
        if t.contains("walk") { return 3.5 }
        if t.contains("cycl") || t.contains("bik") { return 7.5 }
        if t.contains("swim") { return 8.0 }
        if t.contains("strength") || t.contains("lift") || t.contains("weight") { return 5.0 }
        if t.contains("hik") { return 6.0 }
        if t.contains("yoga") { return 2.5 }
        if t.contains("pilates") { return 3.0 }
        if t.contains("row") { return 7.0 }
        if t.contains("cardio") { return 7.0 }
        return 5.0 // generic "Workout"
    }

    /// Estimated calories burned for `minutes` of `type` at the given body weight.
    static func estimate(type: String, minutes: Int, weightKg: Double = 70) -> Int {
        guard minutes > 0 else { return 0 }
        let kcal = met(for: type) * 3.5 * weightKg / 200 * Double(minutes)
        return Int(kcal.rounded())
    }
}

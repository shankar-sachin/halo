import SwiftUI

/// App-wide colours and gradients tuned for the Liquid Glass look.
enum Theme {
    static let todoTint = Color(red: 0.36, green: 0.55, blue: 1.0)      // periwinkle blue
    static let notesTint = Color(red: 1.0, green: 0.72, blue: 0.28)     // warm amber
    static let dietTint = Color(red: 0.28, green: 0.82, blue: 0.62)     // mint green
    static let habitsTint = Color(red: 0.58, green: 0.45, blue: 0.95)   // indigo
    static let waterTint = Color(red: 0.26, green: 0.68, blue: 0.95)    // sky blue
    static let workoutsTint = Color(red: 1.0, green: 0.45, blue: 0.38)  // coral
    static let moodTint = Color(red: 1.0, green: 0.58, blue: 0.79)      // pink
    static let pillsTint = Color(red: 0.95, green: 0.45, blue: 0.55)    // rose
    static let weightTint = Color(red: 0.45, green: 0.78, blue: 0.78)   // teal
    static let sleepTint = Color(red: 0.42, green: 0.40, blue: 0.78)    // deep indigo

    // Category tints — reuse a representative tracker hue so each hub feels cohesive.
    static let nutritionTint = dietTint     // Diet, Water
    static let healthTint = workoutsTint     // Workouts, Weight, Sleep, Pills
    static let mindTint = habitsTint          // Mood, Habits
    static let organizeTint = todoTint        // To-Do, Notes

    /// Widest a column of content should grow to; keeps cards/charts readable on iPad.
    static let maxContentWidth: CGFloat = 680

    /// Soft ambient background gradient that lets glass refraction read nicely.
    static func backdrop(_ tint: Color) -> some View {
        LinearGradient(
            colors: [
                tint.opacity(0.28),
                tint.opacity(0.08),
                Color(.systemBackground).opacity(0.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

extension View {
    /// Caps content to a readable column and centers it. A no-op on iPhone-width
    /// screens (where the cap exceeds the available width); keeps cards from
    /// stretching edge-to-edge on iPad.
    func readableWidth(_ width: CGFloat = Theme.maxContentWidth) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }
}

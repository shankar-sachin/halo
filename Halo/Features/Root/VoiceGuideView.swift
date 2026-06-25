import SwiftUI

/// Showcases the Siri phrases the app understands. Wired to live App Intents in Phase 3.
struct VoiceGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Phrase: Identifiable {
        let id = UUID()
        let icon: String
        let tint: Color
        let text: String
    }

    private let phrases: [Phrase] = [
        .init(icon: "checklist", tint: Theme.todoTint,
              text: "“Halo, add a to-do: eat one cup of greek yogurt by 5:30 pm today.”"),
        .init(icon: "checkmark.circle", tint: Theme.todoTint,
              text: "“Halo, I finished eating one cup of greek yogurt at 5:15 pm.”"),
        .init(icon: "note.text", tint: Theme.notesTint,
              text: "“Halo, add a note that I shipped the release.”"),
        .init(icon: "fork.knife", tint: Theme.dietTint,
              text: "“Halo, log that I ate a cup of greek yogurt.”"),
        .init(icon: "drop.fill", tint: Theme.waterTint,
              text: "“Halo, log a glass of water.”"),
        .init(icon: "figure.run", tint: Theme.workoutsTint,
              text: "“Halo, log a 30 minute run.”"),
        .init(icon: "face.smiling", tint: Theme.moodTint,
              text: "“Halo, I feel great today.”"),
        .init(icon: "checkmark.seal", tint: Theme.habitsTint,
              text: "“Halo, add a habit to meditate” · “mark my meditation habit done.”"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 16) {
                            ForEach(phrases) { phrase in
                                GlassCard(tint: phrase.tint) {
                                    HStack(alignment: .top, spacing: 14) {
                                        Image(systemName: phrase.icon)
                                            .font(.title2)
                                            .foregroundStyle(phrase.tint)
                                            .frame(width: 32)
                                        Text(phrase.text)
                                            .font(.callout)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.backdrop(.purple))
            .navigationTitle("Talk to Halo")
            .navigationSubtitle("Control your lifestyle with your voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    VoiceGuideView()
}

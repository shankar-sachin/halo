import SwiftUI

struct RootTabView: View {
    @AppStorage(SettingsKey.hasOnboarded, store: .shared) private var hasOnboarded = false
    @State private var showVoiceMode = false

    var body: some View {
        TabView {
            Tab("To-Do", systemImage: "checklist") {
                TodoListView()
            }
            Tab("Notes", systemImage: "note.text") {
                NotesListView()
            }
            Tab("Diet", systemImage: "fork.knife") {
                DietView()
            }
            Tab("Habits", systemImage: "checkmark.seal") {
                HabitsView()
            }
            Tab("Water", systemImage: "drop.fill") {
                WaterView()
            }
            Tab("Workouts", systemImage: "figure.run") {
                WorkoutsView()
            }
            Tab("Mood", systemImage: "face.smiling") {
                MoodView()
            }
            Tab("Pills", systemImage: "pills.fill") {
                PillsView()
            }
        }
        .tabViewBottomAccessory {
            Button {
                showVoiceMode = true
            } label: {
                Label("Talk to Halo", systemImage: "mic.fill")
                    .font(.callout.weight(.semibold))
            }
            .tint(.purple)
        }
        .sheet(isPresented: $showVoiceMode) {
            VoiceModeView()
        }
        .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
            OnboardingView()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(DataController.shared.container)
}

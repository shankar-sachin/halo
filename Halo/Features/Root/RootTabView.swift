import SwiftUI

/// Tabs in the root tab bar; the `Home` dashboard cards switch tabs via this.
enum HomeTab: Hashable {
    case home, todo, notes, diet, habits, water, workouts, mood, pills
}

struct RootTabView: View {
    @AppStorage(SettingsKey.hasOnboarded, store: .shared) private var hasOnboarded = false
    @State private var showVoiceMode = false
    @State private var selection: HomeTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView(selection: $selection)
            }
            Tab("To-Do", systemImage: "checklist", value: .todo) {
                TodoListView()
            }
            Tab("Notes", systemImage: "note.text", value: .notes) {
                NotesListView()
            }
            Tab("Diet", systemImage: "fork.knife", value: .diet) {
                DietView()
            }
            Tab("Habits", systemImage: "checkmark.seal", value: .habits) {
                HabitsView()
            }
            Tab("Water", systemImage: "drop.fill", value: .water) {
                WaterView()
            }
            Tab("Workouts", systemImage: "figure.run", value: .workouts) {
                WorkoutsView()
            }
            Tab("Mood", systemImage: "face.smiling", value: .mood) {
                MoodView()
            }
            Tab("Pills", systemImage: "pills.fill", value: .pills) {
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
        .fullScreenCover(isPresented: Binding(
            get: { !hasOnboarded },
            set: { presenting in if !presenting { hasOnboarded = true } }
        )) {
            OnboardingView()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(DataController.shared.container)
}

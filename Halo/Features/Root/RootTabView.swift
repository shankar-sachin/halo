import SwiftUI

/// Top-level destinations. Home is the dashboard; the rest are tracker *categories* whose hubs
/// link into the individual trackers — keeping the bar within iOS's limit.
enum HomeTab: Hashable {
    case home, nutrition, health, mind, organize
}

struct RootTabView: View {
    @AppStorage(SettingsKey.hasOnboarded, store: .shared) private var hasOnboarded = false
    @State private var showVoiceMode = false
    @State private var selection: HomeTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
            }
            Tab("Nutrition", systemImage: "fork.knife", value: .nutrition) {
                CategoryHubView(title: "Nutrition", tint: Theme.nutritionTint, links: [
                    TrackerLink("Diet", systemImage: "fork.knife", tint: Theme.dietTint) { DietView() },
                    TrackerLink("Water", systemImage: "drop.fill", tint: Theme.waterTint) { WaterView() },
                ])
            }
            Tab("Health", systemImage: "heart.fill", value: .health) {
                CategoryHubView(title: "Health", tint: Theme.healthTint, links: [
                    TrackerLink("Workouts", systemImage: "figure.run", tint: Theme.workoutsTint) { WorkoutsView() },
                    TrackerLink("Weight", systemImage: "scalemass", tint: Theme.weightTint) { WeightView() },
                    TrackerLink("Sleep", systemImage: "bed.double.fill", tint: Theme.sleepTint) { SleepView() },
                    TrackerLink("Pills", systemImage: "pills.fill", tint: Theme.pillsTint) { PillsView() },
                ])
            }
            Tab("Mind", systemImage: "brain.head.profile", value: .mind) {
                CategoryHubView(title: "Mind", tint: Theme.mindTint, links: [
                    TrackerLink("Mood", systemImage: "face.smiling", tint: Theme.moodTint) { MoodView() },
                    TrackerLink("Habits", systemImage: "checkmark.seal", tint: Theme.habitsTint) { HabitsView() },
                ])
            }
            Tab("Organize", systemImage: "checklist", value: .organize) {
                CategoryHubView(title: "Organize", tint: Theme.organizeTint, links: [
                    TrackerLink("To-Do", systemImage: "checklist", tint: Theme.todoTint) { TodoListView() },
                    TrackerLink("Notes", systemImage: "note.text", tint: Theme.notesTint) { NotesListView() },
                ])
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewBottomAccessory {
            Button {
                showVoiceMode = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.habitsTint, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .stroke(.white.opacity(0.55), lineWidth: 1.5)
                        .padding(3)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                .shadow(color: .purple.opacity(0.35), radius: 6, y: 1)
                .accessibilityLabel("Talk to Halo")
            }
            .buttonStyle(.plain)
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

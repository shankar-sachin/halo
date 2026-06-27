import SwiftUI

/// A hub that organizes preferences by tracker — each row opens a focused settings page.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Trackers") {
                    link("Diet", systemImage: "fork.knife", tint: Theme.dietTint) { DietSettingsView() }
                    link("Water", systemImage: "drop.fill", tint: Theme.waterTint) { WaterSettingsView() }
                    link("Sleep", systemImage: "bed.double.fill", tint: Theme.sleepTint) { SleepSettingsView() }
                }
                Section("Assistant") {
                    link("Voice & Siri", systemImage: "mic.fill", tint: Theme.habitsTint) { AssistantSettingsView() }
                    link("Daily Coach", systemImage: "sparkles", tint: Theme.moodTint) { CoachSettingsView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backdrop(Theme.dietTint))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.dietTint)
    }

    private func link<Destination: View>(_ title: String, systemImage: String, tint: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }
        }
    }
}

#Preview {
    SettingsView()
}

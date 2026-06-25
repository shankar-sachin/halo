import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.dailyCalorieBudget, store: .shared) private var budget: Int = SettingsDefault.dailyCalorieBudget
    @AppStorage(SettingsKey.syncToHealth, store: .shared) private var syncToHealth: Bool = SettingsDefault.syncToHealth
    @AppStorage(SettingsKey.waterGoalML, store: .shared) private var waterGoal: Int = SettingsDefault.waterGoalML
    @AppStorage(SettingsKey.listenInBackground, store: .shared) private var listenInBackground: Bool = SettingsDefault.listenInBackground

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Calorie Budget") {
                    Stepper(value: $budget, in: 1000...5000, step: 50) {
                        HStack {
                            Text("Target")
                            Spacer()
                            Text("\(budget) kcal")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                Section("Daily Water Goal") {
                    Stepper(value: $waterGoal, in: 500...5000, step: 250) {
                        HStack {
                            Text("Target")
                            Spacer()
                            Text("\(waterGoal) ml")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                Section {
                    Toggle("Sync meals to Apple Health", isOn: $syncToHealth)
                } footer: {
                    Text("When on, each logged meal is written to Apple Health as dietary energy.")
                }
                Section {
                    Toggle("Keep listening in background", isOn: $listenInBackground)
                } footer: {
                    Text("Lets you say “Halo, …” while the app is running in the background. Keeps the microphone active — the orange indicator stays on and it uses more battery. Stops if the app is force-quit.")
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
}

#Preview {
    SettingsView()
}

import SwiftUI

struct WaterSettingsView: View {
    @AppStorage(SettingsKey.waterGoalML, store: .shared) private var waterGoal: Int = SettingsDefault.waterGoalML

    var body: some View {
        Form {
            Section("Daily Water Goal") {
                Stepper(value: $waterGoal, in: 500...5000, step: 250) {
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(waterGoal) ml").foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop(Theme.waterTint))
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.waterTint)
    }
}

struct SleepSettingsView: View {
    @AppStorage(SettingsKey.sleepGoalHours, store: .shared) private var sleepGoal: Int = SettingsDefault.sleepGoalHours

    var body: some View {
        Form {
            Section("Sleep Goal") {
                Stepper(value: $sleepGoal, in: 4...12, step: 1) {
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(sleepGoal) h").foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop(Theme.sleepTint))
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.sleepTint)
    }
}

struct AssistantSettingsView: View {
    @AppStorage(SettingsKey.listenInBackground, store: .shared) private var listenInBackground: Bool = SettingsDefault.listenInBackground

    var body: some View {
        Form {
            Section {
                Toggle("Keep listening in background", isOn: $listenInBackground)
            } footer: {
                Text("Lets you say “Halo, …” while the app is running in the background. Keeps the microphone active — the orange indicator stays on and it uses more battery. Stops if the app is force-quit.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop(Theme.habitsTint))
        .navigationTitle("Voice & Siri")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.habitsTint)
    }
}

struct CoachSettingsView: View {
    @AppStorage(SettingsKey.coachEnabled, store: .shared) private var coachEnabled: Bool = SettingsDefault.coachEnabled
    @AppStorage(SettingsKey.coachHour, store: .shared) private var coachHour: Int = SettingsDefault.coachHour

    var body: some View {
        Form {
            Section {
                Toggle("Daily coach briefing", isOn: $coachEnabled)
                if coachEnabled {
                    Stepper(value: $coachHour, in: 5...22, step: 1) {
                        HStack {
                            Text("Remind me at")
                            Spacer()
                            Text(hourLabel(coachHour)).foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("A gentle daily nudge to check in on your day across every tracker.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop(Theme.moodTint))
        .navigationTitle("Daily Coach")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.moodTint)
        .onChange(of: coachEnabled) { _, on in updateCoach(enabled: on, hour: coachHour) }
        .onChange(of: coachHour) { _, hour in if coachEnabled { updateCoach(enabled: true, hour: hour) } }
    }

    private func updateCoach(enabled: Bool, hour: Int) {
        Task {
            if enabled {
                await NotificationService.shared.scheduleDailyCoach(hour: hour)
            } else {
                NotificationService.shared.cancelDailyCoach()
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

import SwiftUI

struct DietSettingsView: View {
    @AppStorage(SettingsKey.dailyCalorieBudget, store: .shared) private var budget: Int = SettingsDefault.dailyCalorieBudget
    @AppStorage(SettingsKey.syncToHealth, store: .shared) private var syncToHealth: Bool = SettingsDefault.syncToHealth
    @AppStorage(SettingsKey.dietType, store: .shared) private var dietType: String = DietType.omnivore.rawValue
    @AppStorage(SettingsKey.dietLikes, store: .shared) private var likes: String = ""
    @AppStorage(SettingsKey.dietAvoid, store: .shared) private var avoid: String = ""
    @AppStorage(SettingsKey.dietAllergies, store: .shared) private var allergies: String = ""

    var body: some View {
        Form {
            Section("Daily Calorie Budget") {
                Stepper(value: $budget, in: 1000...5000, step: 50) {
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(budget) kcal").foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
            Section("Eating Style") {
                DietTypeChips(rawValue: $dietType)
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            }
            Section("Foods You Love") {
                TextField("e.g. pasta, berries, salmon", text: $likes, axis: .vertical)
                    .lineLimit(1...3)
            }
            Section("Foods to Avoid") {
                TextField("e.g. mushrooms, very spicy", text: $avoid, axis: .vertical)
                    .lineLimit(1...3)
            }
            Section {
                AllergenChips(allergies: $allergies)
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            } header: {
                Text("Allergies")
            } footer: {
                Text("Halo never suggests meals with these.")
            }
            Section {
                Toggle("Sync meals to Apple Health", isOn: $syncToHealth)
            } footer: {
                Text("When on, each logged meal is written to Apple Health as dietary energy.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop(Theme.dietTint))
        .navigationTitle("Diet")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.dietTint)
    }
}

#Preview {
    NavigationStack { DietSettingsView() }
}

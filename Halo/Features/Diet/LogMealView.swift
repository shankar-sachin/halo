import SwiftUI
import SwiftData

struct LogMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// `nil` means logging a new meal; otherwise we edit this entry.
    var entry: DietEntry? = nil

    @State private var foodText: String = ""
    @State private var calories: Int = 0
    @State private var loggedAt: Date = .now
    @State private var isEstimating = false
    @State private var estimateSource: CalorieSource?

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you eat?") {
                    TextField("e.g. one cup of greek yogurt", text: $foodText, axis: .vertical)
                        .lineLimit(1...3)
                        .onChange(of: foodText) { estimateSource = nil }
                }
                Section("Calories") {
                    HStack {
                        TextField("kcal", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                        Spacer()
                        Button {
                            Task { await estimate() }
                        } label: {
                            if isEstimating {
                                ProgressView()
                            } else {
                                Label("Estimate", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.glass)
                        .disabled(foodText.trimmingCharacters(in: .whitespaces).isEmpty || isEstimating)
                    }
                    if let estimateSource {
                        Text(estimateSource == .ai
                             ? "Estimated on-device with Apple Intelligence."
                             : "Estimated from the built-in food database.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("When") {
                    DatePicker("Logged at", selection: $loggedAt)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backdrop(Theme.dietTint))
            .navigationTitle(entry == nil ? "Log Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(entry == nil ? "Log" : "Save") { Task { await save() } }
                        .disabled(foodText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
        .tint(Theme.dietTint)
    }

    private func load() {
        guard let entry else { return }
        foodText = entry.foodText
        calories = entry.calories
        loggedAt = entry.loggedAt
        estimateSource = entry.source
    }

    private func estimate() async {
        isEstimating = true
        defer { isEstimating = false }
        let result = await CalorieEstimator.shared.estimate(for: foodText)
        calories = result.calories
        estimateSource = result.source
    }

    private func save() async {
        let trimmed = foodText.trimmingCharacters(in: .whitespaces)
        // Auto-estimate if the user never set a calorie value.
        if calories <= 0 {
            await estimate()
        }
        let source = estimateSource ?? .manual

        if let entry {
            // Editing in place — update fields without re-firing notifications/Health writes.
            entry.foodText = trimmed
            entry.calories = max(calories, 0)
            entry.loggedAt = loggedAt
            entry.source = source
            try? context.save()
        } else {
            await MealLogger(context: context).log(
                foodText: trimmed,
                calories: max(calories, 0),
                at: loggedAt,
                source: source
            )
        }
        dismiss()
    }
}

#Preview {
    LogMealView()
        .modelContainer(DataController.shared.container)
}

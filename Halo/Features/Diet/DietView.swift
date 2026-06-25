import SwiftUI
import SwiftData

struct DietView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DietEntry.loggedAt, order: .reverse) private var allEntries: [DietEntry]
    @AppStorage(SettingsKey.dailyCalorieBudget, store: .shared) private var budget: Int = SettingsDefault.dailyCalorieBudget

    @State private var showAdd = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var editingEntry: DietEntry?
    @State private var suggestion: String?
    @State private var loadingSuggestion = false

    private var todayEntries: [DietEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.loggedAt) }
    }
    private var consumedToday: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CalorieRingView(consumed: consumedToday, budget: budget)
                        .padding(.top, 8)

                    if todayEntries.isEmpty {
                        ContentUnavailableView(
                            "No meals logged today",
                            systemImage: "fork.knife",
                            description: Text("Tap + or say “Halo, log a meal.”")
                        )
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(todayEntries) { entry in
                                DietEntryRow(entry: entry)
                                    .onTapGesture { editingEntry = entry }
                                    .contextMenu {
                                        Button { editingEntry = entry } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            context.delete(entry)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Theme.backdrop(Theme.dietTint))
            .navigationTitle("Diet")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            loadingSuggestion = true
                            suggestion = await CommandActions(context: context).suggestMeal("")
                            loadingSuggestion = false
                        }
                    } label: {
                        Image(systemName: loadingSuggestion ? "lightbulb.circle" : "lightbulb")
                    }
                    .disabled(loadingSuggestion)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInsights = true } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                LogMealView()
            }
            .sheet(item: $editingEntry) { entry in
                LogMealView(entry: entry)
            }
            .sheet(isPresented: $showInsights) {
                DietInsightsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Meal idea", isPresented: Binding(get: { suggestion != nil }, set: { if !$0 { suggestion = nil } })) {
                Button("OK", role: .cancel) { suggestion = nil }
            } message: {
                Text(suggestion ?? "")
            }
        }
        .tint(Theme.dietTint)
    }
}

#Preview {
    DietView()
        .modelContainer(DataController.shared.container)
}

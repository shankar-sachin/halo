import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.loggedAt, order: .reverse) private var workouts: [Workout]

    @State private var showAdd = false
    @State private var healthWorkouts: [HealthWorkout] = []

    /// A unified row backed by either a local `Workout` or an Apple Health workout.
    private struct Item: Identifiable {
        let id: String
        let type: String
        let durationMinutes: Int
        let calories: Int
        let date: Date
        let symbol: String
        let local: Workout?      // nil for Apple Health workouts (read-only)
    }

    private var items: [Item] {
        let localItems = workouts.map {
            Item(id: "local-\($0.persistentModelID.hashValue)", type: $0.type, durationMinutes: $0.durationMinutes,
                 calories: $0.calories, date: $0.loggedAt, symbol: $0.symbol, local: $0)
        }
        let healthItems = healthWorkouts.map {
            Item(id: "hk-\($0.id.uuidString)", type: $0.type, durationMinutes: $0.durationMinutes,
                 calories: $0.calories, date: $0.date, symbol: $0.symbol, local: nil)
        }
        return (localItems + healthItems).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "figure.run",
                        description: Text("Log one with + or “Halo, log a 30 minute run” — your Apple Watch workouts show up here too.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                row(item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.backdrop(Theme.workoutsTint))
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddWorkoutView() }
            .task { healthWorkouts = await HealthKitService.shared.recentWorkouts() }
            .refreshable { healthWorkouts = await HealthKitService.shared.recentWorkouts() }
        }
        .tint(Theme.workoutsTint)
    }

    private func row(_ item: Item) -> some View {
        GlassCard(tint: Theme.workoutsTint) {
            HStack(spacing: 14) {
                Image(systemName: item.symbol)
                    .font(.title)
                    .foregroundStyle(Theme.workoutsTint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.type.capitalized).font(.body.weight(.medium))
                        if item.local == nil {
                            Label("Apple Health", systemImage: "applewatch")
                                .labelStyle(.iconOnly)
                                .font(.caption)
                                .foregroundStyle(Theme.workoutsTint)
                                .accessibilityLabel("From Apple Health")
                        }
                    }
                    Text("\(item.durationMinutes) min • \(item.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if item.calories > 0 {
                    Text("\(item.calories) kcal")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                if let local = item.local {
                    Button(role: .destructive) { context.delete(local) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(DataController.shared.container)
}

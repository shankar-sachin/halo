import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.loggedAt, order: .reverse) private var workouts: [Workout]

    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "figure.run",
                        description: Text("Tap + or say “Halo, log a 30 minute run.”")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                row(workout)
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
        }
        .tint(Theme.workoutsTint)
    }

    private func row(_ workout: Workout) -> some View {
        GlassCard(tint: Theme.workoutsTint) {
            HStack(spacing: 14) {
                Image(systemName: workout.symbol)
                    .font(.title)
                    .foregroundStyle(Theme.workoutsTint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.type.capitalized).font(.body.weight(.medium))
                    Text("\(workout.durationMinutes) min • \(workout.loggedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if workout.calories > 0 {
                    Text("\(workout.calories) kcal")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                Button(role: .destructive) { context.delete(workout) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(DataController.shared.container)
}

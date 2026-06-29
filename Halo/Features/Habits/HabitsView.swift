import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var showAdd = false
    @State private var newName = ""

    var body: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView(
                    "No habits yet",
                    systemImage: "checkmark.seal",
                    description: Text("Tap + or say “Halo, add a habit to meditate.”")
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(habits) { habit in
                            habitRow(habit)
                        }
                    }
                    .padding()
                    .readableWidth()
                }
            }
        }
        .background(Theme.backdrop(Theme.habitsTint))
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .alert("New Habit", isPresented: $showAdd) {
            TextField("e.g. Meditate", text: $newName)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Add") { add() }
        }
        .tint(Theme.habitsTint)
    }

    private func habitRow(_ habit: Habit) -> some View {
        GlassCard(tint: Theme.habitsTint) {
            HStack(spacing: 14) {
                Button {
                    withAnimation { habit.toggle() }
                } label: {
                    Image(systemName: habit.isCompleted() ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundStyle(habit.isCompleted() ? Theme.habitsTint : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.body.weight(.medium))
                    if habit.streak > 0 {
                        Label("\(habit.streak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .contextMenu {
                Button(role: .destructive) { context.delete(habit) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func add() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(Habit(name: trimmed))
        newName = ""
    }
}

#Preview {
    HabitsView()
        .modelContainer(DataController.shared.container)
}

import SwiftUI
import SwiftData

/// The "Today" front door — a glanceable summary of every tracker. Each card deep-links
/// into its tab via the shared `selection` binding owned by `RootTabView`.
struct HomeView: View {
    @Binding var selection: HomeTab

    @Query(sort: \DietEntry.loggedAt, order: .reverse) private var meals: [DietEntry]
    @Query(sort: \WaterEntry.loggedAt, order: .reverse) private var water: [WaterEntry]
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var todos: [TodoItem]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \MoodEntry.loggedAt, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \Workout.loggedAt, order: .reverse) private var workouts: [Workout]
    @Query(sort: \PillLog.loggedAt, order: .reverse) private var pills: [PillLog]
    @Query(sort: \WeightEntry.loggedAt, order: .reverse) private var weights: [WeightEntry]
    @Query(sort: \SleepEntry.loggedAt, order: .reverse) private var sleeps: [SleepEntry]

    @AppStorage(SettingsKey.dailyCalorieBudget, store: .shared) private var budget: Int = SettingsDefault.dailyCalorieBudget
    @AppStorage(SettingsKey.waterGoalML, store: .shared) private var waterGoal: Int = SettingsDefault.waterGoalML

    @State private var showSettings = false

    private let columns = [GridItem(.adaptive(minimum: 165), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calorieHero
                    LazyVGrid(columns: columns, spacing: 12) {
                        waterCard
                        habitsCard
                        todoCard
                        moodCard
                        workoutCard
                        pillCard
                        weightCard
                        sleepCard
                    }
                }
                .readableWidth()
                .padding()
                .padding(.bottom, 30)
            }
            .background(Theme.backdrop(Theme.todoTint))
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InsightsView()
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .tint(Theme.todoTint)
    }

    // MARK: - Hero

    private var consumed: Int { meals.filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.calories } }

    private var calorieHero: some View {
        Button { selection = .diet } label: {
            GlassCard(tint: Theme.dietTint) {
                VStack(spacing: 4) {
                    CalorieRingView(consumed: consumed, budget: budget)
                    Text("Diet").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.dietTint)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stat cards

    private var todayWater: Int { water.filter { Calendar.current.isDateInToday($0.loggedAt) }.reduce(0) { $0 + $1.amountML } }
    private var waterCard: some View {
        statCard(tint: Theme.waterTint, icon: "drop.fill", title: "Water",
                 value: "\(todayWater)",
                 caption: "of \(waterGoal) ml") { selection = .water }
    }

    private var doneHabits: Int { habits.filter { $0.isCompleted() }.count }
    private var bestStreak: Int { habits.map(\.streak).max() ?? 0 }
    private var habitsCard: some View {
        statCard(tint: Theme.habitsTint, icon: "checkmark.seal.fill", title: "Habits",
                 value: habits.isEmpty ? "—" : "\(doneHabits)/\(habits.count)",
                 caption: bestStreak > 0 ? "🔥 \(bestStreak) day streak" : "tap to start") { selection = .habits }
    }

    private var openTodos: [TodoItem] { todos.filter { !$0.isDone } }
    private var todoCard: some View {
        statCard(tint: Theme.todoTint, icon: "checklist", title: "To-Do",
                 value: "\(openTodos.count)",
                 caption: openTodos.first.map { "next: \($0.title)" } ?? "all caught up") { selection = .todo }
    }

    private var moodCard: some View {
        let last = moods.first
        return statCard(tint: Theme.moodTint, icon: "face.smiling.fill", title: "Mood",
                        value: last?.emoji ?? "—",
                        caption: last.map { MoodEntry.label(for: $0.rating) } ?? "tap to log") { selection = .mood }
    }

    private var todayWorkouts: [Workout] { workouts.filter { Calendar.current.isDateInToday($0.loggedAt) } }
    private var workoutCard: some View {
        let minutes = todayWorkouts.reduce(0) { $0 + $1.durationMinutes }
        return statCard(tint: Theme.workoutsTint, icon: "figure.run", title: "Workouts",
                        value: todayWorkouts.isEmpty ? "—" : "\(minutes)m",
                        caption: todayWorkouts.isEmpty ? "none today" : "\(todayWorkouts.count) logged") { selection = .workouts }
    }

    private var todayPills: [PillLog] { pills.filter { Calendar.current.isDateInToday($0.loggedAt) } }
    private var pillCard: some View {
        statCard(tint: Theme.pillsTint, icon: "pills.fill", title: "Pills",
                 value: todayPills.isEmpty ? "—" : "\(todayPills.count)",
                 caption: todayPills.isEmpty ? "none today" : "taken today") { selection = .pills }
    }

    private var weightCard: some View {
        let latest = weights.first
        return navCard(tint: Theme.weightTint, icon: "scalemass", title: "Weight",
                       value: latest.map { format($0.weightKg) } ?? "—",
                       caption: latest.map { $0.loggedAt.formatted(date: .abbreviated, time: .omitted) } ?? "tap to log") {
            WeightView()
        }
    }

    private var sleepCard: some View {
        let latest = sleeps.first
        return navCard(tint: Theme.sleepTint, icon: "bed.double.fill", title: "Sleep",
                       value: latest?.label ?? "—",
                       caption: latest != nil ? "last night" : "tap to log") {
            SleepView()
        }
    }

    private func format(_ kg: Double) -> String {
        kg.rounded() == kg ? "\(Int(kg)) kg" : String(format: "%.1f kg", kg)
    }

    private func navCard<Destination: View>(tint: Color, icon: String, title: String, value: String, caption: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            cardBody(tint: tint, icon: icon, title: title, value: value, caption: caption)
        }
        .buttonStyle(.plain)
    }

    private func statCard(tint: Color, icon: String, title: String, value: String, caption: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            cardBody(tint: tint, icon: icon, title: title, value: value, caption: caption)
        }
        .buttonStyle(.plain)
    }

    private func cardBody(tint: Color, icon: String, title: String, value: String, caption: String) -> some View {
        GlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Good night"
        }
    }
}

#Preview {
    HomeView(selection: .constant(.home))
        .modelContainer(DataController.shared.container)
}

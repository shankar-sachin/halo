import SwiftUI
import SwiftData

struct SleepView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepEntry.loggedAt, order: .reverse) private var entries: [SleepEntry]
    @AppStorage(SettingsKey.sleepGoalHours, store: .shared) private var goal: Int = SettingsDefault.sleepGoalHours

    @State private var healthNights: [HealthSleepNight] = []
    @State private var showAdd = false
    @State private var input = ""
    @State private var coachTip: String?
    @State private var loadingTip = false

    private struct Item: Identifiable {
        let id: String
        let hours: Double
        let date: Date
        let fromHealth: Bool
        let local: SleepEntry?
    }

    private var items: [Item] {
        let local = entries.map {
            Item(id: "local-\($0.persistentModelID.hashValue)", hours: $0.hoursAsleep, date: $0.loggedAt, fromHealth: false, local: $0)
        }
        // Don't double-count a night that's both logged manually and present in Health.
        let localDays = Set(entries.map { Calendar.current.startOfDay(for: $0.loggedAt) })
        let health = healthNights
            .filter { !localDays.contains(Calendar.current.startOfDay(for: $0.date)) }
            .map { Item(id: "hk-\($0.id.uuidString)", hours: $0.hoursAsleep, date: $0.date, fromHealth: true, local: nil) }
        return (local + health).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No sleep logged",
                        systemImage: "bed.double.fill",
                        description: Text("Add a night with + or say “Halo, I slept 7 hours.” Apple Watch sleep shows up here too.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            averageCard
                            coachCard
                            ForEach(items) { item in row(item) }
                        }
                        .padding()
                        .readableWidth()
                    }
                }
            }
            .background(Theme.backdrop(Theme.sleepTint))
            .navigationTitle("Sleep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Log Sleep", isPresented: $showAdd) {
                TextField("e.g. 7.5", text: $input)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { input = "" }
                Button("Add") { add() }
            } message: { Text("Enter hours slept.") }
            .task { healthNights = await HealthKitService.shared.recentSleep() }
            .refreshable { healthNights = await HealthKitService.shared.recentSleep() }
        }
        .tint(Theme.sleepTint)
    }

    private var average: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.hours } / Double(items.count)
    }

    private var averageCard: some View {
        GlassCard(tint: Theme.sleepTint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average").font(.caption.weight(.semibold)).foregroundStyle(Theme.sleepTint)
                    Text(String(format: "%.1f h", average))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("goal \(goal) h").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: average >= Double(goal) ? "moon.stars.fill" : "moon.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.sleepTint)
            }
        }
    }

    // MARK: - Sleep coach (AI tip with a deterministic fallback)

    private var coachCard: some View {
        GlassCard(tint: Theme.sleepTint) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sleep Coach", systemImage: "sparkles").font(.headline).foregroundStyle(Theme.sleepTint)
                if let coachTip {
                    Text(coachTip).font(.subheadline)
                } else {
                    Text("Get a personalized tip based on your recent nights.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Button {
                    Task { await loadCoach() }
                } label: {
                    if loadingTip {
                        ProgressView()
                    } else {
                        Label(coachTip == nil ? "Get sleep tips" : "Refresh", systemImage: "moon.zzz.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.glass)
                .tint(Theme.sleepTint)
                .disabled(loadingTip)
            }
        }
    }

    private func loadCoach() async {
        loadingTip = true
        let recent = Array(items.prefix(7))
        coachTip = await HaloIntelligence.sleepCoach(facts: sleepFacts(recent)) ?? fallbackTip(recent)
        loadingTip = false
    }

    /// Stats fed to the model — numbers are computed here so the model only words them.
    private func sleepFacts(_ recent: [Item]) -> String {
        let count = recent.count
        let avg = recent.reduce(0) { $0 + $1.hours } / Double(count)
        let met = recent.filter { $0.hours >= Double(goal) }.count
        let shortest = recent.map(\.hours).min() ?? 0
        let longest = recent.map(\.hours).max() ?? 0
        return """
        Sleep goal: \(goal) h/night.
        Last \(count) night\(count == 1 ? "" : "s") averaged \(String(format: "%.1f", avg)) h.
        \(met) of \(count) night\(count == 1 ? "" : "s") met the goal.
        Shortest \(String(format: "%.1f", shortest)) h, longest \(String(format: "%.1f", longest)) h.
        """
    }

    /// Templated tip used when Apple Intelligence is unavailable (e.g. the simulator).
    private func fallbackTip(_ recent: [Item]) -> String {
        let avg = recent.reduce(0) { $0 + $1.hours } / Double(recent.count)
        let spread = (recent.map(\.hours).max() ?? 0) - (recent.map(\.hours).min() ?? 0)
        let consistency = spread > 1.5
            ? " Your nights vary by about \(String(format: "%.1f", spread)) h — a steadier schedule helps most."
            : ""
        if avg >= Double(goal) {
            return "You're averaging \(String(format: "%.1f", avg)) h against your \(goal) h goal — great work. Keep a consistent bedtime to lock it in.\(consistency)"
        }
        let deficitMin = Int(((Double(goal) - avg) * 60).rounded())
        return "You're averaging \(String(format: "%.1f", avg)) h, about \(deficitMin) min short of your \(goal) h goal. Try winding down and heading to bed a little earlier tonight.\(consistency)"
    }

    private func row(_ item: Item) -> some View {
        GlassCard(tint: Theme.sleepTint) {
            HStack(spacing: 14) {
                Image(systemName: "bed.double.fill").font(.title2).foregroundStyle(Theme.sleepTint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(label(item.hours)).font(.body.weight(.semibold))
                        if item.fromHealth {
                            Image(systemName: "applewatch").font(.caption).foregroundStyle(Theme.sleepTint)
                                .accessibilityLabel("From Apple Health")
                        }
                    }
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
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

    private func label(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func add() {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        guard let hours = Double(normalized), hours > 0 else { input = ""; return }
        context.insert(SleepEntry(hoursAsleep: min(hours, 24)))
        input = ""
    }
}

#Preview {
    SleepView()
        .modelContainer(DataController.shared.container)
}

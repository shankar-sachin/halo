import SwiftUI
import SwiftData

struct SleepView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepEntry.loggedAt, order: .reverse) private var entries: [SleepEntry]
    @AppStorage(SettingsKey.sleepGoalHours, store: .shared) private var goal: Int = SettingsDefault.sleepGoalHours

    @State private var healthNights: [HealthSleepNight] = []
    @State private var showAdd = false
    @State private var input = ""

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
                            ForEach(items) { item in row(item) }
                        }
                        .padding()
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

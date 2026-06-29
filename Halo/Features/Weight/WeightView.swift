import SwiftUI
import SwiftData
import Charts

struct WeightView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.loggedAt, order: .reverse) private var entries: [WeightEntry]

    @State private var healthWeights: [HealthWeight] = []
    @State private var showAdd = false
    @State private var input = ""

    private struct Item: Identifiable {
        let id: String
        let weightKg: Double
        let date: Date
        let fromHealth: Bool
        let local: WeightEntry?
    }

    private var items: [Item] {
        let local = entries.map {
            Item(id: "local-\($0.persistentModelID.hashValue)", weightKg: $0.weightKg, date: $0.loggedAt, fromHealth: false, local: $0)
        }
        let health = healthWeights.map {
            Item(id: "hk-\($0.id.uuidString)", weightKg: $0.weightKg, date: $0.date, fromHealth: true, local: nil)
        }
        return (local + health).sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No weigh-ins yet",
                    systemImage: "scalemass",
                    description: Text("Add one with + or say “Halo, log my weight 80 kilos.”")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if items.count > 1 { trendCard }
                        ForEach(items) { item in row(item) }
                    }
                    .padding()
                    .readableWidth()
                }
            }
        }
        .background(Theme.backdrop(Theme.weightTint))
        .navigationTitle("Weight")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .alert("Log Weight", isPresented: $showAdd) {
            TextField("e.g. 80", text: $input)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { input = "" }
            Button("Add") { add() }
        } message: { Text("Enter your weight in kilograms.") }
        .task { healthWeights = await HealthKitService.shared.recentWeights() }
        .refreshable { healthWeights = await HealthKitService.shared.recentWeights() }
        .tint(Theme.weightTint)
    }

    private var trendCard: some View {
        GlassCard(tint: Theme.weightTint) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Trend").font(.headline)
                Chart(items.reversed()) { item in
                    LineMark(x: .value("Date", item.date), y: .value("kg", item.weightKg))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.weightTint)
                    PointMark(x: .value("Date", item.date), y: .value("kg", item.weightKg))
                        .foregroundStyle(Theme.weightTint)
                }
                .frame(height: 160)
            }
        }
    }

    private func row(_ item: Item) -> some View {
        GlassCard(tint: Theme.weightTint) {
            HStack(spacing: 14) {
                Image(systemName: "scalemass").font(.title2).foregroundStyle(Theme.weightTint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(format(item.weightKg)).font(.body.weight(.semibold))
                        if item.fromHealth {
                            Image(systemName: "applewatch").font(.caption).foregroundStyle(Theme.weightTint)
                                .accessibilityLabel("From Apple Health")
                        }
                    }
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
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

    private func format(_ kg: Double) -> String {
        let kgStr = kg.rounded() == kg ? String(Int(kg)) : String(format: "%.1f", kg)
        return "\(kgStr) kg"
    }

    private func add() {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        guard let kg = Double(normalized), kg > 0 else { input = ""; return }
        context.insert(WeightEntry(weightKg: kg))
        if UserDefaults.shared.bool(forKey: SettingsKey.syncToHealth) {
            Task { await HealthKitService.shared.saveWeight(kg: kg) }
        }
        input = ""
    }
}

#Preview {
    WeightView()
        .modelContainer(DataController.shared.container)
}

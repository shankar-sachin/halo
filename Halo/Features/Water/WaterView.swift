import SwiftUI
import SwiftData

struct WaterView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WaterEntry.loggedAt, order: .reverse) private var entries: [WaterEntry]
    @AppStorage(SettingsKey.waterGoalML, store: .shared) private var goal: Int = SettingsDefault.waterGoalML

    private var todayEntries: [WaterEntry] {
        entries.filter { Calendar.current.isDateInToday($0.loggedAt) }
    }
    private var consumed: Int { todayEntries.reduce(0) { $0 + $1.amountML } }
    private var fraction: Double { goal > 0 ? min(Double(consumed) / Double(goal), 1) : 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progress
                quickAdd
                if !todayEntries.isEmpty { history }
            }
            .padding()
            .padding(.bottom, 30)
            .readableWidth()
        }
        .background(Theme.backdrop(Theme.waterTint))
        .navigationTitle("Water")
        .tint(Theme.waterTint)
    }

    private var progress: some View {
        GlassCard(tint: Theme.waterTint) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().stroke(Theme.waterTint.opacity(0.18), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Theme.waterTint.gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.smooth, value: fraction)
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill").foregroundStyle(Theme.waterTint)
                        Text("\(consumed)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("of \(goal) ml").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 180, height: 180)
                Text("\(glasses) of \(goalGlasses) glasses")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var quickAdd: some View {
        HStack(spacing: 12) {
            addButton(label: "Glass", ml: 250, icon: "cup.and.saucer.fill")
            addButton(label: "Bottle", ml: 500, icon: "waterbottle.fill")
        }
    }

    private func addButton(label: String, ml: Int, icon: String) -> some View {
        Button {
            withAnimation { context.insert(WaterEntry(amountML: ml)) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text("\(label) +\(ml)ml").font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
        .tint(Theme.waterTint)
    }

    private var history: some View {
        GlassCard(tint: Theme.waterTint) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today").font(.headline)
                ForEach(todayEntries) { entry in
                    HStack {
                        Image(systemName: "drop.fill").foregroundStyle(Theme.waterTint)
                        Text("\(entry.amountML) ml")
                        Spacer()
                        Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                        Button {
                            context.delete(entry)
                        } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var glasses: Int { Int((Double(consumed) / Double(WaterEntry.glassML)).rounded()) }
    private var goalGlasses: Int { max(Int((Double(goal) / Double(WaterEntry.glassML)).rounded()), 1) }
}

#Preview {
    WaterView()
        .modelContainer(DataController.shared.container)
}

import WidgetKit
import SwiftUI

struct HabitEntry: TimelineEntry {
    let date: Date
    let doneToday: Int
    let total: Int
    let bestStreak: Int
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: .now, doneToday: 2, total: 3, bestStreak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> HabitEntry {
        let summary = WidgetStore.habitStreakSummary()
        return HabitEntry(
            date: .now,
            doneToday: summary.doneToday,
            total: summary.total,
            bestStreak: summary.bestStreak
        )
    }
}

struct HabitStreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    private var fraction: Double {
        guard entry.total > 0 else { return 0 }
        return min(Double(entry.doneToday) / Double(entry.total), 1)
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: fraction) {
                Image(systemName: "checkmark.seal.fill")
            } currentValueLabel: {
                Text("\(entry.doneToday)")
            }
            .gaugeStyle(.accessoryCircular)
            .containerBackground(.fill.tertiary, for: .widget)
        default:
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(entry.bestStreak)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                }
                Text("day streak").font(.caption2).foregroundStyle(.secondary)
                if entry.total > 0 {
                    Text("\(entry.doneToday)/\(entry.total) habits today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(entry.doneToday == entry.total ? Theme.habitsTint : .secondary)
                } else {
                    Text("No habits yet")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct HabitStreakWidget: Widget {
    let kind = "HabitStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitStreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Streak")
        .description("Today's habit progress and your best streak.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

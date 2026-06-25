import WidgetKit
import SwiftUI

struct CalorieEntry: TimelineEntry {
    let date: Date
    let consumed: Int
    let budget: Int
}

struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: .now, consumed: 1200, budget: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> CalorieEntry {
        CalorieEntry(date: .now, consumed: WidgetStore.caloriesToday(), budget: SettingsDefault.budget)
    }
}

struct CalorieRingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalorieEntry

    private var remaining: Int { max(entry.budget - entry.consumed, 0) }
    private var fraction: Double {
        guard entry.budget > 0 else { return 0 }
        return min(Double(entry.consumed) / Double(entry.budget), 1)
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: fraction) {
                Image(systemName: "fork.knife")
            } currentValueLabel: {
                Text("\(entry.consumed)")
            }
            .gaugeStyle(.accessoryCircular)
            .containerBackground(.fill.tertiary, for: .widget)
        default:
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Theme.dietTint.opacity(0.18), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Theme.dietTint.gradient,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(entry.consumed)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("kcal").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Text(entry.consumed > entry.budget ? "\(entry.consumed - entry.budget) over" : "\(remaining) left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.consumed > entry.budget ? .orange : Theme.dietTint)
            }
            .padding(8)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct CalorieRingWidget: Widget {
    let kind = "CalorieRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieRingWidgetView(entry: entry)
        }
        .configurationDisplayName("Calorie Ring")
        .description("Today's calories against your daily budget.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

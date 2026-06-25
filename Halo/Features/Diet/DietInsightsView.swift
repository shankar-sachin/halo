import SwiftUI
import SwiftData
import Charts

struct DietInsightsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.dailyCalorieBudget, store: .shared) private var budget: Int = SettingsDefault.dailyCalorieBudget

    private struct DayTotal: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Int
    }

    @State private var week: [DayTotal] = []
    @State private var streak = 0

    private var average: Int {
        guard !week.isEmpty else { return 0 }
        return week.reduce(0) { $0 + $1.calories } / week.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(tint: Theme.dietTint) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Last 7 days")
                                .font(.headline)
                            chart
                                .frame(height: 200)
                        }
                    }

                    HStack(spacing: 16) {
                        statCard(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak",
                                 icon: "flame.fill", tint: .orange)
                        statCard(value: "\(average)", label: "avg kcal/day",
                                 icon: "chart.bar.fill", tint: Theme.dietTint)
                    }
                }
                .padding()
            }
            .background(Theme.backdrop(Theme.dietTint))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: load)
        }
        .tint(Theme.dietTint)
    }

    private var chart: some View {
        Chart {
            ForEach(week) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Calories", day.calories)
                )
                .foregroundStyle(day.calories > budget ? Color.orange.gradient : Theme.dietTint.gradient)
                .cornerRadius(6)
            }
            RuleMark(y: .value("Budget", budget))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(.secondary)
                .annotation(position: .top, alignment: .leading) {
                    Text("Budget \(budget)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, tint: Color) -> some View {
        GlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func load() {
        let logger = MealLogger(context: context)
        week = logger.dailyTotals(days: 7).map { DayTotal(date: $0.date, calories: $0.calories) }
        streak = logger.currentStreak()
    }
}

#Preview {
    DietInsightsView()
        .modelContainer(DataController.shared.container)
}

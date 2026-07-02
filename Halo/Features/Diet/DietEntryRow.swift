import SwiftUI

struct DietEntryRow: View {
    let entry: DietEntry

    var body: some View {
        GlassCard(tint: Theme.dietTint) {
            HStack(spacing: 14) {
                Image(systemName: entry.category.symbol)
                    .font(.title)
                    .foregroundStyle(Theme.dietTint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.foodText)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                        if entry.source == .ai {
                            Label("Estimated", systemImage: "sparkles")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if entry.hasMacros {
                        Text("P \(entry.protein)g · C \(entry.carbs)g · F \(entry.fat)g")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.dietTint)
                    }
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.calories)")
                        .font(.title3.weight(.bold).monospacedDigit())
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

import SwiftUI

struct DietEntryRow: View {
    let entry: DietEntry

    var body: some View {
        GlassCard(tint: Theme.dietTint) {
            HStack(spacing: 14) {
                Image(systemName: "fork.knife.circle.fill")
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

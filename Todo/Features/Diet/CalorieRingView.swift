import SwiftUI

/// A "halo" progress ring showing calories consumed against the daily budget.
struct CalorieRingView: View {
    let consumed: Int
    let budget: Int

    private var fraction: Double {
        guard budget > 0 else { return 0 }
        return min(Double(consumed) / Double(budget), 1.0)
    }

    private var over: Bool { consumed > budget }
    private var remaining: Int { max(budget - consumed, 0) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 18)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: over
                            ? [.orange, .red]
                            : [Theme.dietTint, Theme.dietTint.opacity(0.7), .teal],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: fraction)

            VStack(spacing: 2) {
                Text("\(consumed)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("of \(budget) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(over ? "\(consumed - budget) over" : "\(remaining) left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(over ? .orange : Theme.dietTint)
            }
        }
        .frame(width: 200, height: 200)
        .padding(8)
    }
}

#Preview {
    CalorieRingView(consumed: 1250, budget: 2000)
}

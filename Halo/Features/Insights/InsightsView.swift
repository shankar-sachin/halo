import SwiftUI
import SwiftData

/// Cross-tracker patterns plus an end-of-day reflection. Patterns are computed deterministically by
/// `CorrelationEngine`; the AI only words the summary and the reflection (each with a fallback).
struct InsightsView: View {
    @Environment(\.modelContext) private var context

    @State private var correlations: [Correlation] = []
    @State private var aiSummary: String?
    @State private var reflection: String?
    @State private var loadingReflection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                patternsCard
                if let aiSummary { summaryCard(aiSummary) }
                reflectionCard
            }
            .padding()
            .padding(.bottom, 30)
            .readableWidth()
        }
        .background(Theme.backdrop(Theme.habitsTint))
        .navigationTitle("Insights")
        .task { await loadPatterns() }
    }

    private var patternsCard: some View {
        GlassCard(tint: Theme.habitsTint) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Patterns", systemImage: "chart.xyaxis.line")
                    .font(.headline).foregroundStyle(Theme.habitsTint)
                if correlations.isEmpty {
                    Text("Keep logging your mood alongside workouts, water, sleep, and habits — patterns will appear here once there's enough history.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(correlations) { c in
                        Label {
                            Text(c.headline).font(.subheadline)
                        } icon: {
                            Image(systemName: c.symbol).foregroundStyle(Theme.habitsTint)
                        }
                    }
                }
            }
        }
    }

    private func summaryCard(_ text: String) -> some View {
        GlassCard(tint: Theme.moodTint) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Coach", systemImage: "sparkles").font(.headline).foregroundStyle(Theme.moodTint)
                Text(text).font(.subheadline)
            }
        }
    }

    private var reflectionCard: some View {
        GlassCard(tint: Theme.sleepTint) {
            VStack(alignment: .leading, spacing: 12) {
                Label("End of day", systemImage: "moon.stars").font(.headline).foregroundStyle(Theme.sleepTint)
                if let reflection {
                    Text(reflection).font(.subheadline)
                } else {
                    Text("Wrap up your day with a warm recap across every tracker.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Button {
                    Task { await reflect() }
                } label: {
                    if loadingReflection {
                        ProgressView()
                    } else {
                        Label(reflection == nil ? "Reflect on my day" : "Refresh", systemImage: "moon.stars.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.glass)
                .tint(Theme.sleepTint)
                .disabled(loadingReflection)
            }
        }
    }

    private func loadPatterns() async {
        correlations = CorrelationEngine.correlations(in: context)
        guard !correlations.isEmpty else { return }
        let facts = correlations.map(\.headline).joined(separator: "\n")
        aiSummary = await HaloIntelligence.correlationInsight(facts: facts)
    }

    private func reflect() async {
        loadingReflection = true
        reflection = await CommandActions(context: context).reflectDay()
        loadingReflection = false
    }
}

#Preview {
    NavigationStack { InsightsView() }
        .modelContainer(DataController.shared.container)
}

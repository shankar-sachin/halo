import SwiftUI
import SwiftData

struct PillsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PillLog.loggedAt, order: .reverse) private var pills: [PillLog]

    @State private var showAdd = false

    private var today: [PillLog] { pills.filter { Calendar.current.isDateInToday($0.loggedAt) } }
    private var earlier: [PillLog] { pills.filter { !Calendar.current.isDateInToday($0.loggedAt) } }

    var body: some View {
        NavigationStack {
            Group {
                if pills.isEmpty {
                    ContentUnavailableView(
                        "No pills logged",
                        systemImage: "pills.fill",
                        description: Text("Tap + or say “Halo, I ate my digestion pill.”")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("Today")
                            ForEach(today) { row($0) }
                            if !earlier.isEmpty {
                                sectionHeader("Earlier")
                                ForEach(earlier) { row($0) }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.backdrop(Theme.pillsTint))
            .navigationTitle("Pills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddPillView() }
        }
        .tint(Theme.pillsTint)
    }

    @ViewBuilder private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).foregroundStyle(.secondary).padding(.top, 4)
    }

    private func row(_ pill: PillLog) -> some View {
        GlassCard(tint: Theme.pillsTint) {
            HStack(spacing: 14) {
                Image(systemName: "pills.fill")
                    .font(.title)
                    .foregroundStyle(Theme.pillsTint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pill.name).font(.body.weight(.medium))
                    HStack(spacing: 6) {
                        if !pill.purpose.isEmpty {
                            Text("for \(pill.purpose)")
                        }
                        Text(pill.loggedAt.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contextMenu {
                Button(role: .destructive) { context.delete(pill) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    PillsView()
        .modelContainer(DataController.shared.container)
}

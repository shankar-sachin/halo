import SwiftUI
import SwiftData

struct MoodView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodEntry.loggedAt, order: .reverse) private var entries: [MoodEntry]

    @State private var note = ""
    @State private var journal = ""
    @State private var reflecting = false
    @State private var reflection: (rating: Int, note: String, journal: String, reply: String)?
    @State private var reflectFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                picker
                if !entries.isEmpty { history }
            }
            .padding()
            .padding(.bottom, 30)
            .readableWidth()
        }
        .background(Theme.backdrop(Theme.moodTint))
        .navigationTitle("Mood")
        .tint(Theme.moodTint)
    }

    private var picker: some View {
        GlassCard(tint: Theme.moodTint) {
            VStack(spacing: 14) {
                Text("How are you feeling?").font(.headline)
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            log(rating)
                        } label: {
                            VStack(spacing: 4) {
                                Text(MoodEntry.emoji(for: rating)).font(.system(size: 34))
                                Text(MoodEntry.label(for: rating))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                TextField("Add a note (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                DisclosureGroup("Journal") {
                    VStack(spacing: 10) {
                        TextField("What's on your mind?", text: $journal, axis: .vertical)
                            .lineLimit(3...8)
                            .textFieldStyle(.roundedBorder)
                        if !journal.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                Task { await reflect() }
                            } label: {
                                if reflecting {
                                    ProgressView()
                                } else {
                                    Label("Reflect", systemImage: "sparkles")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .buttonStyle(.glass)
                            .tint(Theme.moodTint)
                            .disabled(reflecting)
                        }
                        if reflectFailed {
                            Text("I couldn't read a mood from that — tap an emoji to log it yourself.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let reflection {
                            reflectionPreview(reflection)
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.subheadline)
                .tint(Theme.moodTint)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// The AI's read of the journal entry, shown for confirmation before it's logged.
    private func reflectionPreview(_ r: (rating: Int, note: String, journal: String, reply: String)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(MoodEntry.emoji(for: r.rating)).font(.title3)
                Text(MoodEntry.label(for: r.rating)).font(.subheadline.weight(.medium))
            }
            if !r.note.isEmpty {
                Text(r.note).font(.caption).foregroundStyle(.secondary)
            }
            if !r.reply.isEmpty {
                Label { Text(r.reply).font(.subheadline) } icon: {
                    Image(systemName: "sparkles").foregroundStyle(Theme.moodTint)
                }
            }
            Button("Log this mood") { logReflection() }
                .buttonStyle(.glass)
                .tint(Theme.moodTint)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var history: some View {
        GlassCard(tint: Theme.moodTint) {
            VStack(alignment: .leading, spacing: 10) {
                Text("History").font(.headline)
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Text(entry.emoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.label).font(.subheadline.weight(.medium))
                            if !entry.note.isEmpty {
                                Text(entry.note).font(.caption).foregroundStyle(.secondary)
                            }
                            if !entry.journal.isEmpty {
                                Text(entry.journal)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                            Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contextMenu {
                        Button(role: .destructive) { context.delete(entry) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func reflect() async {
        reflecting = true
        reflectFailed = false
        reflection = await CommandActions(context: context).reflectOrFallback(journal)
        reflectFailed = reflection == nil
        reflecting = false
    }

    private func logReflection() {
        guard let r = reflection else { return }
        withAnimation {
            context.insert(MoodEntry(rating: r.rating, note: r.note, journal: r.journal))
            note = ""
            journal = ""
            reflection = nil
        }
    }

    private func log(_ rating: Int) {
        withAnimation {
            context.insert(MoodEntry(
                rating: rating,
                note: note.trimmingCharacters(in: .whitespaces),
                journal: journal.trimmingCharacters(in: .whitespaces)
            ))
            note = ""
            journal = ""
        }
    }
}

#Preview {
    MoodView()
        .modelContainer(DataController.shared.container)
}

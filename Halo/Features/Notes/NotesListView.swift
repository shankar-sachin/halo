import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    @State private var selected: Note?
    @State private var showAdd = false
    @State private var searchText = ""

    private var filtered: [Note] {
        guard !searchText.isEmpty else { return notes }
        return notes.filter { $0.body.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                ContentUnavailableView(
                    "No notes yet",
                    systemImage: "note.text",
                    description: Text("Tap + or say “Halo, add a note.”")
                )
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filtered) { note in
                        Button { selected = note } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.backdrop(Theme.notesTint))
        .searchable(text: $searchText, prompt: "Search notes")
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NoteEditorView(note: nil)
        }
        .sheet(item: $selected) { note in
            NoteEditorView(note: note)
        }
        .tint(Theme.notesTint)
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(filtered[index]) }
    }
}

#Preview {
    NotesListView()
        .modelContainer(DataController.shared.container)
}

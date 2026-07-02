import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let note: Note?

    @State private var text = AttributedString()
    @State private var selection = AttributedTextSelection()
    @State private var extracting = false
    @State private var extractResult: String?

    var body: some View {
        NavigationStack {
            TextEditor(text: $text, selection: $selection)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Theme.backdrop(Theme.notesTint))
                .navigationTitle(note == nil ? "New Note" : "Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Button { apply { $0.bold() } } label: { Image(systemName: "bold") }
                        Button { apply { $0.italic() } } label: { Image(systemName: "italic") }
                        Button { applyFont(.title2.bold()) } label: { Image(systemName: "textformat.size.larger") }
                        Button { applyFont(.body) } label: { Image(systemName: "textformat") }
                        Spacer()
                    }
                    if note != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await extractTodos() }
                            } label: {
                                if extracting {
                                    ProgressView()
                                } else {
                                    Label("Extract To-Dos", systemImage: "text.badge.checkmark")
                                }
                            }
                            .disabled(extracting)
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save)
                            .disabled(String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .onAppear { if let note { text = note.attributed } }
                .alert("Extract To-Dos", isPresented: .init(
                    get: { extractResult != nil },
                    set: { if !$0 { extractResult = nil } }
                )) {
                    Button("OK") { extractResult = nil }
                } message: {
                    Text(extractResult ?? "")
                }
        }
        .tint(Theme.notesTint)
    }

    /// Transforms the font of the current selection (e.g. toggle bold/italic).
    private func apply(_ transform: @escaping (Font) -> Font) {
        text.transformAttributes(in: &selection) { container in
            container.font = transform(container.font ?? .body)
        }
    }

    /// Sets an explicit font on the current selection (headings / body).
    private func applyFont(_ font: Font) {
        text.transformAttributes(in: &selection) { container in
            container.font = font
        }
    }

    /// Turns the open note's action items into to-dos (AI, with a split-based fallback).
    private func extractTodos() async {
        guard let note else { return }
        extracting = true
        let tasks = await CommandActions(context: context).extractTodos(from: note)
        extracting = false
        extractResult = tasks.isEmpty
            ? "I couldn't find any tasks in this note."
            : "Created \(tasks.count) to-do\(tasks.count == 1 ? "" : "s") from this note."
    }

    private func save() {
        if let note {
            note.attributed = text
        } else {
            let new = Note(body: "")
            new.attributed = text
            context.insert(new)
        }
        dismiss()
    }
}

#Preview {
    NoteEditorView(note: nil)
        .modelContainer(DataController.shared.container)
}

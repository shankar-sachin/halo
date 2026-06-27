import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let note: Note?

    @State private var text = AttributedString()
    @State private var selection = AttributedTextSelection()

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
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save)
                            .disabled(String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .onAppear { if let note { text = note.attributed } }
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

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let note: Note?

    @State private var text = AttributedString()

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Theme.backdrop(Theme.notesTint))
                .navigationTitle(note == nil ? "New Note" : "Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
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

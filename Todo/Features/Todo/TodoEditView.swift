import SwiftUI
import SwiftData

struct TodoEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// `nil` means we are creating a new item.
    let item: TodoItem?

    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = .now
    @State private var recurrence: Recurrence = .none

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you need to do?", text: $title, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section {
                    Toggle("Remind me", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("When", selection: $dueDate)
                        Picker("Repeat", selection: $recurrence) {
                            ForEach(Recurrence.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backdrop(Theme.todoTint))
            .navigationTitle(item == nil ? "New To-Do" : "Edit To-Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
        .tint(Theme.todoTint)
    }

    private func load() {
        guard let item else { return }
        title = item.title
        recurrence = item.recurrence
        if let due = item.dueDate {
            hasDueDate = true
            dueDate = due
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let due = hasDueDate ? dueDate : nil
        // Repeat only applies when there's a due date to advance from.
        let effectiveRecurrence = due == nil ? .none : recurrence
        if let item {
            item.title = trimmed
            item.dueDate = due
            item.recurrence = effectiveRecurrence
        } else {
            context.insert(TodoItem(title: trimmed, dueDate: due, recurrence: effectiveRecurrence))
        }
        dismiss()
    }
}

#Preview {
    TodoEditView(item: nil)
        .modelContainer(DataController.shared.container)
}

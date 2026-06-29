import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var items: [TodoItem]

    @State private var editing: TodoItem?
    @State private var showAdd = false
    @State private var searchText = ""

    private var filtered: [TodoItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    private var overdue: [TodoItem] { filtered.filter { $0.isOverdue } }
    private var open: [TodoItem] { filtered.filter { !$0.isDone && !$0.isOverdue }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) } }
    private var done: [TodoItem] { filtered.filter { $0.isDone } }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No to-dos yet",
                    systemImage: "checklist",
                    description: Text("Tap + or say “Halo, add a to-do.”")
                )
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    section("Overdue", overdue, tint: .red)
                    section("To Do", open, tint: Theme.todoTint)
                    section("Completed", done, tint: .secondary)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.backdrop(Theme.todoTint))
        .searchable(text: $searchText, prompt: "Search to-dos")
        .navigationTitle("To-Do")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            TodoEditView(item: nil)
        }
        .sheet(item: $editing) { item in
            TodoEditView(item: item)
        }
        .tint(Theme.todoTint)
    }

    @ViewBuilder
    private func section(_ title: String, _ rows: [TodoItem], tint: Color) -> some View {
        if !rows.isEmpty {
            Section(title) {
                ForEach(rows) { item in
                    TodoRowView(item: item) { toggle(item) }
                        .contentShape(.rect)
                        .onTapGesture { editing = item }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggle(item)
                            } label: {
                                Label(item.isDone ? "Reopen" : "Done",
                                      systemImage: item.isDone ? "arrow.uturn.left" : "checkmark")
                            }
                            .tint(item.isDone ? .gray : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func toggle(_ item: TodoItem) {
        withAnimation {
            item.isDone.toggle()
            item.completedAt = item.isDone ? .now : nil
        }
        if item.isDone {
            RecurrenceEngine.scheduleNext(after: item, in: context)
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(DataController.shared.container)
}

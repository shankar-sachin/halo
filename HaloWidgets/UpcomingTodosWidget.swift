import WidgetKit
import SwiftUI

struct TodosEntry: TimelineEntry {
    let date: Date
    let todos: [TodoSummary]
}

struct TodosProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodosEntry {
        TodosEntry(date: .now, todos: [
            TodoSummary(title: "Eat greek yogurt", dueDate: .now),
            TodoSummary(title: "Call mom", dueDate: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodosEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodosEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> TodosEntry {
        TodosEntry(date: .now, todos: WidgetStore.upcomingTodos(limit: 4))
    }
}

struct UpcomingTodosWidgetView: View {
    let entry: TodosEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("To-Do", systemImage: "checklist")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.todoTint)

            if entry.todos.isEmpty {
                Spacer()
                Text("All caught up 🎉")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.todos) { todo in
                    HStack(spacing: 6) {
                        Image(systemName: "circle")
                            .font(.caption2)
                            .foregroundStyle(Theme.todoTint)
                        Text(todo.title)
                            .font(.footnote)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if let due = todo.dueDate {
                            Text(due, format: .dateTime.hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct UpcomingTodosWidget: Widget {
    let kind = "UpcomingTodosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodosProvider()) { entry in
            UpcomingTodosWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming To-Dos")
        .description("Your next few open to-dos.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

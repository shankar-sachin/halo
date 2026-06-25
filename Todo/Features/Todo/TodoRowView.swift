import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isDone ? Color.green : Theme.todoTint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .strikethrough(item.isDone, color: .secondary)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                if let due = item.dueDate {
                    HStack(spacing: 8) {
                        Label(dueText(due), systemImage: "clock")
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                        if item.recurrence != .none {
                            Label(item.recurrence.label, systemImage: "repeat")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
                if let completedAt = item.completedAt, item.isDone {
                    Label("Done \(completedAt.formatted(date: .omitted, time: .shortened))",
                          systemImage: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func dueText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

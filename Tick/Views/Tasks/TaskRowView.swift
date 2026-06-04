import SwiftUI

/// A single task row. The completion toggle uses a spring + checkmark fill for
/// a satisfying "done" feel.
struct TaskRowView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(NotificationManager.self) private var notifications

    let task: TaskItem
    /// Whether to show the owning project chip (hidden inside a project view).
    var showsProject: Bool = true

    private var scheduler: TaskScheduler {
        TaskScheduler(context: context, notifications: notifications)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            completionButton

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(task.title)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    if let dueDate = task.dueDate {
                        dueDatePill(dueDate)
                    }
                    if showsProject, let project = task.project {
                        projectChip(project)
                    }
                }
            }

            Spacer()

            if task.priority != .p4 {
                Image(systemName: task.priority.symbolName)
                    .foregroundStyle(task.priority.color)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { appState.editingTask = task }
        .contextMenu {
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                toggleCompletion()
            }
            Button("Edit") { appState.editingTask = task }
            Divider()
            Button("Delete", role: .destructive) { scheduler.delete(task) }
        }
    }

    private var completionButton: some View {
        Button(action: toggleCompletion) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isCompleted ? task.priority.color : task.priority.color.opacity(0.7))
                .symbolEffect(.bounce, value: task.isCompleted)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.return, modifiers: .command)
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scheduler.toggleCompletion(task)
        }
    }

    private func dueDatePill(_ date: Date) -> some View {
        Label(date.dueDisplay, systemImage: "clock")
            .font(.caption2)
            .foregroundStyle(task.isOverdue ? .red : .secondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: Theme.Radius.pill))
    }

    private func projectChip(_ project: Project) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            ProjectIconView(token: project.iconToken, colorHex: project.colorHex, size: 10)
            Text(project.name)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: Theme.Radius.pill))
    }
}

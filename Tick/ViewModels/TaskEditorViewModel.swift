import SwiftUI
import SwiftData

/// What the editor sheet is doing.
enum TaskEditorMode {
    case create(defaultProject: Project?)
    case edit(TaskItem)
}

/// Holds the transient edit buffer for the task editor sheet, plus validation
/// and the commit logic. The buffer pattern means we don't mutate the live
/// SwiftData object until the user saves.
@MainActor
@Observable
final class TaskEditorViewModel {
    var title: String = ""
    var notes: String = ""
    var priority: Priority = .default
    var hasDueDate: Bool = false
    var dueDate: Date = Date.startOfToday.adding(hours: 9)
    var hasReminder: Bool = false

    private let mode: TaskEditorMode

    init(mode: TaskEditorMode) {
        self.mode = mode
        if case .edit(let task) = mode {
            title = task.title
            notes = task.notes
            priority = task.priority
            if let due = task.dueDate {
                hasDueDate = true
                dueDate = due
            }
            hasReminder = !task.reminderList.isEmpty
        }
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Persists the buffer. Returns the saved task so the caller can react.
    @discardableResult
    func save(context: ModelContext, notifications: NotificationManager) async -> TaskItem? {
        guard canSave else { return nil }
        let scheduler = TaskScheduler(context: context, notifications: notifications)
        let resolvedDue = hasDueDate ? dueDate : nil

        let task: TaskItem
        switch mode {
        case .create(let defaultProject):
            task = TaskItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes,
                priority: priority,
                dueDate: resolvedDue,
                project: defaultProject
            )
            context.insert(task)
        case .edit(let existing):
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.notes = notes
            existing.priority = priority
            existing.dueDate = resolvedDue
            task = existing
        }

        try? context.save()

        // Reminder: V1 fires at the due date when enabled.
        if hasReminder, let resolvedDue {
            await scheduler.setReminder(for: task, at: resolvedDue)
        } else {
            await scheduler.setReminder(for: task, at: nil)
        }
        return task
    }
}

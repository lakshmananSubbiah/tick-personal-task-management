import Foundation
import SwiftData

/// A single task. The core domain entity.
///
/// CloudKit-compatibility notes:
/// - No `.unique` constraints.
/// - Every non-optional scalar has a default value.
/// - Relationships are optional; the `reminders` inverse + cascade are declared
///   here, the `project` inverse is declared on `Project.tasks`.
@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""

    /// Plain text in V1. V2 swaps this for rich/markdown notes.
    var notes: String = ""

    /// Raw storage for `Priority` (1...4). Use the `priority` computed wrapper.
    var priorityRaw: Int = Priority.default.rawValue

    /// Optional due date *and time*.
    var dueDate: Date?

    var isCompleted: Bool = false
    var completedAt: Date?

    /// Manual ordering within a list.
    var sortOrder: Int = 0

    var createdAt: Date = Date.now

    /// Owning project. `nil` means the task lives in the Inbox.
    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \Reminder.task)
    var reminders: [Reminder]? = []

    init(
        title: String,
        notes: String = "",
        priority: Priority = .default,
        dueDate: Date? = nil,
        project: Project? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.priorityRaw = priority.rawValue
        self.dueDate = dueDate
        self.project = project
        self.sortOrder = sortOrder
        self.isCompleted = false
        self.createdAt = .now
    }
}

extension TaskItem {
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .default }
        set { priorityRaw = newValue.rawValue }
    }

    var reminderList: [Reminder] {
        reminders ?? []
    }

    /// True if the task has a due date in the past and isn't done.
    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < .now
    }
}

import Foundation
import SwiftData

/// Domain operations that touch both the data model *and* notifications:
/// completing, snoozing, rescheduling, and setting reminders. Keeping these in
/// one place means notification side-effects can never drift out of sync with
/// the task state.
///
/// Design choice (confirmed): **snooze affects the notification only** — it
/// never mutates `dueDate`. The task's due date is the source of truth.
@MainActor
struct TaskScheduler {
    let context: ModelContext
    let notifications: NotificationManager

    // MARK: - Completion

    func toggleCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil

        if task.isCompleted {
            // Cancel any pending reminders for a finished task.
            cancelReminders(for: task)
        }
        save()
    }

    func complete(_ task: TaskItem) {
        guard !task.isCompleted else { return }
        task.isCompleted = true
        task.completedAt = .now
        cancelReminders(for: task)
        save()
    }

    // MARK: - Reminders

    /// Replaces all reminders on a task with a single reminder at `fireDate`,
    /// then registers the OS notification. Passing `nil` clears reminders.
    func setReminder(for task: TaskItem, at fireDate: Date?) async {
        cancelReminders(for: task)
        task.reminders?.removeAll()

        guard let fireDate else { save(); return }

        let reminder = Reminder(fireDate: fireDate)
        reminder.task = task
        context.insert(reminder)

        let identifier = await notifications.schedule(
            title: task.title,
            body: task.notes.isEmpty ? "Reminder" : task.notes,
            fireDate: fireDate,
            taskID: task.id,
            identifier: reminder.requestIdentifier
        )
        reminder.requestIdentifier = identifier
        save()
    }

    /// Re-registers OS notifications for all of a task's reminders. Useful after
    /// app relaunch or when reminder times change.
    func resyncNotifications(for task: TaskItem) async {
        for reminder in task.reminderList where reminder.fireDate > .now {
            await notifications.schedule(
                title: task.title,
                body: task.notes.isEmpty ? "Reminder" : task.notes,
                fireDate: reminder.fireDate,
                taskID: task.id,
                identifier: reminder.requestIdentifier
            )
        }
    }

    func cancelReminders(for task: TaskItem) {
        let ids = task.reminderList.map(\.requestIdentifier).filter { !$0.isEmpty }
        notifications.cancel(identifiers: ids)
    }

    // MARK: - Snooze (notification-only; does not touch dueDate)

    func snooze(_ task: TaskItem, minutes: Int) async {
        await notifications.scheduleSnooze(
            title: task.title,
            body: task.notes.isEmpty ? "Snoozed reminder" : task.notes,
            after: minutes,
            taskID: task.id
        )
    }

    // MARK: - Reschedule (explicitly moves the due date)

    func reschedule(_ task: TaskItem, to newDueDate: Date?) async {
        task.dueDate = newDueDate
        // If a reminder existed, move it to the new due date for convenience.
        if let newDueDate, !task.reminderList.isEmpty {
            await setReminder(for: task, at: newDueDate)
        } else {
            save()
        }
    }

    // MARK: - Deletion

    func delete(_ task: TaskItem) {
        cancelReminders(for: task)
        context.delete(task)
        save()
    }

    // MARK: -

    private func save() {
        do {
            try context.save()
        } catch {
            // V1: log. Later we surface a user-facing error path.
            assertionFailure("Tick save failed: \(error)")
        }
    }
}

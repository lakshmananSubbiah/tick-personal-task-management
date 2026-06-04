import SwiftUI
import SwiftData

/// Tasks not yet filed into a project. The landing spot for quick capture (V2).
struct InboxView: View {
    @Query private var tasks: [TaskItem]

    init() {
        let predicate = #Predicate<TaskItem> { task in
            task.project == nil && !task.isCompleted
        }
        _tasks = Query(
            filter: predicate,
            sort: [SortDescriptor(\TaskItem.sortOrder), SortDescriptor(\TaskItem.createdAt)]
        )
    }

    var body: some View {
        TaskListView(
            title: "Inbox",
            subtitle: nil,
            tasks: tasks,
            emptyMessage: "Inbox zero. Capture a task with ⌘N."
        )
    }
}

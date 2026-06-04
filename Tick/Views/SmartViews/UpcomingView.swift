import SwiftUI
import SwiftData

/// Incomplete tasks due within the next 7 days (including today), sorted by
/// time then priority. Grouping by day is a V1.1 polish item.
struct UpcomingView: View {
    @Query private var tasks: [TaskItem]

    init() {
        let start = DateRanges.upcoming.start
        let end = DateRanges.upcoming.end
        // See TodayView: nil-coalescing avoids SwiftData's force-unwrap SQL bug.
        let sentinel = Date.distantPast
        let predicate = #Predicate<TaskItem> { task in
            !task.isCompleted
                && (task.dueDate ?? sentinel) >= start
                && (task.dueDate ?? sentinel) < end
        }
        _tasks = Query(
            filter: predicate,
            sort: [SortDescriptor(\TaskItem.dueDate), SortDescriptor(\TaskItem.priorityRaw)]
        )
    }

    var body: some View {
        TaskListView(
            title: "Upcoming",
            subtitle: "Next 7 days",
            tasks: tasks,
            emptyMessage: "No tasks scheduled in the next week."
        )
    }
}

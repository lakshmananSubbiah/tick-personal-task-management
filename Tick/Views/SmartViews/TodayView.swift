import SwiftUI
import SwiftData

/// All incomplete tasks due today, across every project, sorted by time then
/// priority.
///
/// SwiftData idiom: a `@Query` can't read "now" from the environment, so we
/// compute the day bounds in `init` and inject them into the predicate.
///
/// Optional `dueDate` is handled with nil-coalescing (`?? .distantPast`) rather
/// than force-unwrap, which SwiftData translates to SQL more reliably.
struct TodayView: View {
    @Query private var tasks: [TaskItem]

    init() {
        let start = DateRanges.today.start
        let end = DateRanges.today.end
        // Use nil-coalescing instead of force-unwrap: SwiftData translates
        // `dueDate! >= start` into SQL that can silently match nothing, whereas
        // `(dueDate ?? sentinel)` translates cleanly. Tasks with no due date map
        // to `.distantPast`, which falls outside the range and is excluded.
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
            title: "Today",
            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month().day()),
            tasks: tasks,
            emptyMessage: "Nothing due today. Enjoy the calm."
        )
    }
}

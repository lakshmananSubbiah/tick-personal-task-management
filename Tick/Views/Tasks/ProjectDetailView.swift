import SwiftUI
import SwiftData

/// All tasks within a single project ("tab"). Incomplete first, then completed.
struct ProjectDetailView: View {
    @Query private var tasks: [TaskItem]
    @Query private var matchingProjects: [Project]

    private let projectID: UUID

    init(projectID: UUID) {
        self.projectID = projectID

        let taskPredicate = #Predicate<TaskItem> { task in
            task.project?.id == projectID
        }
        // Note: `Bool` isn't `Comparable`, so we can't sort by `isCompleted`
        // here. Separating completed tasks into their own section is a Phase 4
        // item; for now they sort alongside by order/due date.
        _tasks = Query(
            filter: taskPredicate,
            sort: [SortDescriptor(\TaskItem.sortOrder), SortDescriptor(\TaskItem.dueDate)]
        )

        let projectPredicate = #Predicate<Project> { $0.id == projectID }
        _matchingProjects = Query(filter: projectPredicate)
    }

    var body: some View {
        TaskListView(
            title: matchingProjects.first?.name ?? "Project",
            subtitle: nil,
            tasks: tasks,
            showsProject: false,
            emptyMessage: "No tasks in this project yet."
        )
    }
}

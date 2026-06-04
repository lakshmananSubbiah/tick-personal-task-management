import SwiftUI

/// What the sidebar currently has selected. Drives the detail column.
enum SidebarSelection: Hashable {
    case today
    case upcoming
    case inbox
    case project(UUID)
}

/// App-wide UI state that isn't persisted: current selection, search text,
/// and which sheet (if any) is presented. Kept deliberately small.
@MainActor
@Observable
final class AppState {
    var selection: SidebarSelection? = .today
    var searchText: String = ""

    /// When set, the task editor sheet is shown for this task (nil title = new).
    var editingTask: TaskItem?
    var isPresentingNewTask: Bool = false
}

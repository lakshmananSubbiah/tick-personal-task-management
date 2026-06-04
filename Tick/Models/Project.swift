import SwiftUI
import SwiftData

/// A top-level container — your "tab" / notebook (Personal, Work, etc.).
/// A `TaskItem` belongs to exactly one `Project`, or to none (the Inbox).
///
/// CloudKit-compatibility notes:
/// - No `.unique` constraints (we rely on `id` and enforce uniqueness in code).
/// - Every non-optional scalar has a default value.
/// - The `tasks` relationship is optional and declares the inverse + cascade.
@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""

    /// Stored as a hex string for portability. Decoded via `Theme`/`Color` ext.
    var colorHex: String = "#0A84FF"

    /// Discriminated icon string: `"sf:<symbol>"` or `"emoji:<char>"`.
    /// Decoded at the view layer (see `ProjectIcon`).
    var iconToken: String = "sf:folder"

    /// Manual ordering in the sidebar.
    var sortOrder: Int = 0

    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.project)
    var tasks: [TaskItem]? = []

    init(
        name: String,
        colorHex: String = "#0A84FF",
        iconToken: String = "sf:folder",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.iconToken = iconToken
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}

extension Project {
    /// Non-optional accessor — SwiftData models to-many as optional for
    /// CloudKit, but callers shouldn't have to unwrap everywhere.
    var taskList: [TaskItem] {
        tasks ?? []
    }

    var incompleteCount: Int {
        taskList.filter { !$0.isCompleted }.count
    }
}

import SwiftUI

/// Shared list renderer used by every view (Today, Upcoming, Inbox, Project).
/// Owns presentation only — the caller supplies the already-filtered tasks via
/// `@Query` so SwiftData drives updates.
struct TaskListView: View {
    let title: String
    let subtitle: String?
    let tasks: [TaskItem]
    var showsProject: Bool = true
    var emptyMessage: String = "No tasks here yet."

    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if tasks.isEmpty {
                ContentUnavailableView {
                    Label(title, systemImage: "checkmark.circle")
                } description: {
                    Text(emptyMessage)
                }
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRowView(task: task, showsProject: showsProject)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .background(.ultraThinMaterial)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.isPresentingNewTask = true
                } label: {
                    Label("New Task", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

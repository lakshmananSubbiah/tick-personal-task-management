import SwiftUI
import SwiftData

/// Root layout: a `NavigationSplitView` with the sidebar (tabs + smart views)
/// on the left and the selected list on the right.
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notifications

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 320)
        } detail: {
            detailColumn
                .frame(minWidth: 480, minHeight: 400)
        }
        .sheet(isPresented: $appState.isPresentingNewTask) {
            TaskEditorView(mode: .create(defaultProject: selectedProject))
        }
        .sheet(item: $appState.editingTask) { task in
            TaskEditorView(mode: .edit(task))
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch appState.selection {
        case .today:
            TodayView()
        case .upcoming:
            UpcomingView()
        case .inbox:
            InboxView()
        case .project(let id):
            ProjectDetailView(projectID: id)
        case nil:
            ContentUnavailableView("Select a list", systemImage: "sidebar.left")
        }
    }

    /// When creating a task while viewing a project, default it to that project.
    private var selectedProject: Project? {
        guard case .project(let id) = appState.selection else { return nil }
        var descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(NotificationManager.shared)
        .modelContainer(AppModelContainer.preview)
        .frame(width: 900, height: 600)
}

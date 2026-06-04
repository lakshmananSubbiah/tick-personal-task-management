import SwiftUI
import SwiftData

/// Sidebar: special smart views up top, then user projects ("tabs").
struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @Query(sort: \Project.sortOrder) private var projects: [Project]

    @State private var isPresentingNewProject = false

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.selection) {
            Section {
                smartRow(.today, title: "Today", systemImage: "star.fill", tint: .orange)
                smartRow(.upcoming, title: "Upcoming", systemImage: "calendar", tint: .red)
                smartRow(.inbox, title: "Inbox", systemImage: "tray.fill", tint: .blue)
            }

            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink(value: SidebarSelection.project(project.id)) {
                        Label {
                            Text(project.name)
                            Spacer()
                            if project.incompleteCount > 0 {
                                Text("\(project.incompleteCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            ProjectIconView(token: project.iconToken, colorHex: project.colorHex)
                        }
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) { delete(project) }
                    }
                }
                .onMove(perform: moveProjects)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                isPresentingNewProject = true
            } label: {
                Label("New Project", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .sheet(isPresented: $isPresentingNewProject) {
            ProjectEditorView()
        }
    }

    private func smartRow(_ selection: SidebarSelection, title: String,
                          systemImage: String, tint: Color) -> some View {
        NavigationLink(value: selection) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(tint)
            }
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        var reordered = projects
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, project) in reordered.enumerated() {
            project.sortOrder = index
        }
        try? context.save()
    }

    private func delete(_ project: Project) {
        // Tasks cascade-delete; clear selection if we're viewing it.
        if case .project(let id) = appState.selection, id == project.id {
            appState.selection = .today
        }
        context.delete(project)
        try? context.save()
    }
}

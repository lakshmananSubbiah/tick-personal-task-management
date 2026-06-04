import SwiftUI
import SwiftData

@main
struct TickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var appState = AppState()
    private let notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(notifications)
                .task {
                    // Ask for notification permission on first launch.
                    await notifications.requestAuthorizationIfNeeded()
                }
        }
        .modelContainer(AppModelContainer.shared)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            TickCommands(appState: appState)
        }
    }
}

/// Keyboard-first menu commands. ⌘N for new task; quick switcher ⌘1…⌘3.
struct TickCommands: Commands {
    @Bindable var appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Task") {
                appState.isPresentingNewTask = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Button("Today") { appState.selection = .today }
                .keyboardShortcut("1", modifiers: .command)
            Button("Upcoming") { appState.selection = .upcoming }
                .keyboardShortcut("2", modifiers: .command)
            Button("Inbox") { appState.selection = .inbox }
                .keyboardShortcut("3", modifiers: .command)
        }
    }
}

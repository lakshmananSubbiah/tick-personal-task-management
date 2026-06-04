import AppKit
import SwiftData
import UserNotifications

/// AppKit delegate bridged into SwiftUI via `@NSApplicationDelegateAdaptor`.
///
/// macOS gotchas handled here:
/// - The `UNUserNotificationCenterDelegate` MUST be set before the app finishes
///   launching, otherwise early notification responses are dropped. We set it
///   in `applicationDidFinishLaunching`.
/// - `willPresent` lets reminders show as banners even while Tick is foreground.
/// - Action responses ("Mark Done", "Snooze") are routed back into the model
///   via `TaskScheduler` on the main actor.
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in
            NotificationManager.shared.registerCategories()
            await NotificationManager.shared.refreshAuthorizationStatus()
        }
    }

    // Show reminders even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // Handle taps and action-button responses.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard
            let idString = userInfo[NotificationManager.Key.taskID] as? String,
            let taskID = UUID(uuidString: idString)
        else { return }

        await handle(actionIdentifier: response.actionIdentifier, taskID: taskID)
    }

    @MainActor
    private func handle(actionIdentifier: String, taskID: UUID) async {
        let context = AppModelContainer.shared.mainContext
        guard let task = Self.fetchTask(id: taskID, in: context) else { return }

        let scheduler = TaskScheduler(context: context, notifications: .shared)

        switch actionIdentifier {
        case NotificationManager.Action.markDone:
            scheduler.complete(task)
        case NotificationManager.Action.snooze15:
            await scheduler.snooze(task, minutes: 15)
        case NotificationManager.Action.snooze60:
            await scheduler.snooze(task, minutes: 60)
        default:
            // Default tap — future: bring the task into focus in the UI.
            break
        }
    }

    @MainActor
    private static func fetchTask(id: UUID, in context: ModelContext) -> TaskItem? {
        var descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

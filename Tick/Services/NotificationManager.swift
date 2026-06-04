import Foundation
import UserNotifications
import SwiftUI

/// Owns everything UserNotifications: permission flow, category/action
/// registration, and scheduling/cancelling requests.
///
/// macOS gotchas handled here:
/// - Categories (with their actions) must be registered up front so the
///   system knows how to render "Mark Done / Snooze" buttons.
/// - Local notifications need NO special sandbox entitlement.
/// - Authorization is requested lazily (on first launch) and we surface the
///   status so the UI can nudge gracefully if denied.
@MainActor
@Observable
final class NotificationManager {

    /// Identifiers shared with `AppDelegate` for routing action responses.
    enum Action {
        static let category = "TICK_TASK_REMINDER"
        static let markDone = "TICK_MARK_DONE"
        static let snooze15 = "TICK_SNOOZE_15"
        static let snooze60 = "TICK_SNOOZE_60"
    }

    /// Userinfo keys carried on each request so the delegate can find the task.
    enum Key {
        static let taskID = "taskID"
    }

    /// Shared instance so the `AppDelegate` (notification routing) and the
    /// SwiftUI environment operate on the same object.
    static let shared = NotificationManager()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    /// Registers notification categories/actions. Call once at launch.
    func registerCategories() {
        let markDone = UNNotificationAction(
            identifier: Action.markDone,
            title: "Mark Done",
            options: []
        )
        let snooze15 = UNNotificationAction(
            identifier: Action.snooze15,
            title: "Snooze 15 min",
            options: []
        )
        let snooze60 = UNNotificationAction(
            identifier: Action.snooze60,
            title: "Snooze 1 hour",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Action.category,
            actions: [markDone, snooze15, snooze60],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// Refreshes `authorizationStatus` from the system.
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Requests permission if not yet determined. Safe to call repeatedly.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        guard authorizationStatus == .notDetermined else {
            return authorizationStatus == .authorized || authorizationStatus == .provisional
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    /// Schedules a one-shot notification at `fireDate` for the given task.
    /// Returns the request identifier (store it on the `Reminder`).
    @discardableResult
    func schedule(
        title: String,
        body: String,
        fireDate: Date,
        taskID: UUID,
        identifier: String = UUID().uuidString
    ) async -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Action.category
        content.userInfo = [Key.taskID: taskID.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await center.add(request)
        return identifier
    }

    /// Schedules a transient snooze alert (not persisted as a `Reminder`).
    func scheduleSnooze(title: String, body: String, after minutes: Int, taskID: UUID) async {
        await schedule(
            title: title,
            body: body,
            fireDate: Date.now.adding(minutes: minutes),
            taskID: taskID,
            identifier: "snooze-\(taskID.uuidString)-\(UUID().uuidString)"
        )
    }

    func cancel(identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}

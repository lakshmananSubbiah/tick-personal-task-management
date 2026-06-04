import Foundation
import SwiftData

/// A scheduled alert for a task. Each `Reminder` owns the identifier of the
/// `UNNotificationRequest` it registered, so cancel/reschedule is deterministic.
///
/// CloudKit-compatibility notes:
/// - No `.unique` constraints.
/// - All non-optional scalars have defaults.
/// - The `task` relationship is optional with an explicit inverse (declared on
///   `TaskItem.reminders`).
@Model
final class Reminder {
    var id: UUID = UUID()

    /// When the notification should fire.
    var fireDate: Date = Date.now

    /// The `UNNotificationRequest` identifier registered for this reminder.
    /// Stored so we can cancel/replace it precisely.
    var requestIdentifier: String = ""

    var task: TaskItem?

    init(fireDate: Date, requestIdentifier: String = UUID().uuidString) {
        self.id = UUID()
        self.fireDate = fireDate
        self.requestIdentifier = requestIdentifier
    }
}

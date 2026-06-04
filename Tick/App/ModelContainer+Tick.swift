import Foundation
import SwiftData

/// Central place that builds the SwiftData `ModelContainer`.
///
/// V1: local store only — `cloudKitDatabase: .none`. The schema is already
/// CloudKit-compatible (no unique constraints, defaulted scalars, optional
/// inverse relationships), so enabling sync later is a one-line change here
/// plus the iCloud/Push entitlements.
enum AppModelContainer {

    static let schema = Schema([
        Project.self,
        TaskItem.self,
        Reminder.self,
    ])

    /// The app-wide container. Built once, lazily.
    static let shared: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // ← flip to `.automatic` to enable sync (V2)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create Tick ModelContainer: \(error)")
        }
    }()

    /// In-memory container for SwiftUI previews, seeded with sample data.
    @MainActor
    static let preview: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            SampleData.seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}

/// Sample data used by previews (and, optionally, first-run onboarding).
enum SampleData {
    @MainActor
    static func seed(into context: ModelContext) {
        let personal = Project(name: "Personal", colorHex: "#30D158", iconToken: "emoji:🏡", sortOrder: 0)
        let work = Project(name: "Work", colorHex: "#0A84FF", iconToken: "sf:briefcase.fill", sortOrder: 1)
        context.insert(personal)
        context.insert(work)

        let t1 = TaskItem(title: "Buy groceries", priority: .p3,
                          dueDate: Date.startOfToday.adding(hours: 18), project: personal)
        let t2 = TaskItem(title: "Ship the Q3 roadmap", notes: "Review with team first",
                          priority: .p1, dueDate: Date.startOfToday.adding(hours: 10), project: work)
        let t3 = TaskItem(title: "Plan weekend trip", priority: .p4,
                          dueDate: Date.startOfDay(daysFromToday: 3).adding(hours: 9), project: personal)
        [t1, t2, t3].forEach(context.insert)

        try? context.save()
    }
}

import XCTest
import SwiftData
@testable import Tick

@MainActor
final class ModelTests: XCTestCase {

    /// Builds an in-memory container so tests never touch the real store.
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AppModelContainer.schema, configurations: [config])
        return container.mainContext
    }

    func testPriorityRoundTrips() {
        for priority in Priority.allCases {
            let task = TaskItem(title: "t", priority: priority)
            XCTAssertEqual(task.priority, priority)
            XCTAssertEqual(task.priorityRaw, priority.rawValue)
        }
    }

    func testDefaultPriorityIsP4() {
        XCTAssertEqual(TaskItem(title: "t").priority, .p4)
    }

    func testOverdueDetection() {
        let past = TaskItem(title: "late", dueDate: Date.now.adding(minutes: -10))
        let future = TaskItem(title: "soon", dueDate: Date.now.adding(hours: 1))
        XCTAssertTrue(past.isOverdue)
        XCTAssertFalse(future.isOverdue)

        let done = TaskItem(title: "done", dueDate: Date.now.adding(minutes: -10))
        done.isCompleted = true
        XCTAssertFalse(done.isOverdue, "Completed tasks are never overdue")
    }

    func testCompletingTaskSetsTimestamp() throws {
        let context = try makeContext()
        let task = TaskItem(title: "finish me")
        context.insert(task)

        let scheduler = TaskScheduler(context: context, notifications: .shared)
        scheduler.complete(task)

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    func testInboxTaskHasNoProject() {
        let task = TaskItem(title: "loose")
        XCTAssertNil(task.project)
    }

    func testColorHexParsingFallsBackGracefully() {
        // Invalid hex should not crash; just exercises the initializer path.
        _ = Color(hex: "not-a-color")
        _ = Color(hex: "#0A84FF")
    }
}

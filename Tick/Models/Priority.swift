import SwiftUI

/// Todoist-style priority. Stored on `TaskItem` as a raw `Int` (`priorityRaw`)
/// for CloudKit portability and clean `#Predicate` queries; this enum is the
/// type-safe wrapper used everywhere in the UI and logic.
enum Priority: Int, CaseIterable, Identifiable, Codable, Sendable {
    case p1 = 1
    case p2 = 2
    case p3 = 3
    case p4 = 4

    var id: Int { rawValue }

    /// Default for newly created tasks (lowest urgency, like Todoist).
    static let `default`: Priority = .p4

    var title: String {
        switch self {
        case .p1: "Priority 1"
        case .p2: "Priority 2"
        case .p3: "Priority 3"
        case .p4: "Priority 4"
        }
    }

    var shortLabel: String {
        switch self {
        case .p1: "P1"
        case .p2: "P2"
        case .p3: "P3"
        case .p4: "P4"
        }
    }

    /// Color coding mirrors Todoist conventions.
    var color: Color {
        switch self {
        case .p1: .red
        case .p2: .orange
        case .p3: .blue
        case .p4: .secondary
        }
    }

    /// SF Symbol used for the priority flag.
    var symbolName: String {
        self == .p4 ? "flag" : "flag.fill"
    }
}

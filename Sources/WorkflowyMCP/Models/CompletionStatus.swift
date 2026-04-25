import Foundation

/// Completion state of a Workflowy node.
///
/// Modeled as a sum type so the `completedAt` timestamp cannot exist while the
/// node is pending. The associated value is optional because the Workflowy API
/// may report `completed=true` without emitting a `completedAt` field.
enum CompletionStatus: Equatable {
    case pending
    case completed(at: Date?)

    /// `true` when this status is `.completed`, regardless of whether a
    /// timestamp was provided.
    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    /// Timestamp of completion when available; `nil` for `.pending` or for
    /// `.completed(at: nil)`.
    var completedAt: Date? {
        if case let .completed(date) = self { return date }
        return nil
    }
}

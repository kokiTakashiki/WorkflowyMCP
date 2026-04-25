import Foundation

/// A Workflowy outline node with its metadata.
///
/// Wire-format concerns (the `data.layoutMode` nesting asymmetry, the
/// `completed`/`completedAt` pair folded into `completionStatus`) live in
/// `WorkflowyNode+Codable.swift` so this type stays a pure domain value.
struct WorkflowyNode: Equatable {
    let id: NodeID
    /// `nil` when the node has no name (Workflowy allows empty nodes).
    let name: String?
    let note: String?
    /// Parent destination, or `nil` when the server did not report one.
    ///
    /// Symmetrical with the request side (`CreateNodeRequest.parent`,
    /// `MoveNodeRequest.parent`): `.root` represents the wire literal
    /// `"None"`, `.node(id)` a concrete parent UUID, and `.target(key)` a
    /// named destination. Keeping the type unified lets callers compare and
    /// reason about parent placement without caring whether a given value
    /// came from a response or was prepared for a request.
    let parent: NodeParent?
    /// Display order among siblings — lower value appears first.
    let priority: Int?
    /// Completion state. Combines the on-wire `completed` flag and `completedAt`
    /// timestamp into a single value so the impossible combination
    /// ("pending with a completedAt") cannot be represented.
    let completionStatus: CompletionStatus
    let layoutMode: LayoutMode?
    let createdAt: Date?
    let modifiedAt: Date?
}

import Foundation

/// Body for `moveNode`.
struct MoveNodeRequest: Encodable {
    /// Destination placement for the node being moved.
    let parent: NodeParent
    let position: Position?

    enum CodingKeys: String, CodingKey {
        case position
        /// `parent_id` is the sole snake_case key in Workflowy request
        /// bodies; every other field is camelCase. The explicit raw value
        /// isolates that API-specified exception to this single line.
        case parent = "parent_id"
    }
}

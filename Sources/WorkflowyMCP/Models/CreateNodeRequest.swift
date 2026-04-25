import Foundation

/// Body for `createNode`.
struct CreateNodeRequest: Encodable {
    let name: String?
    let note: String?
    /// Placement under a specific node, a named target, or the root. `nil`
    /// leaves the API's default placement policy in effect.
    let parent: NodeParent?
    let position: Position?
    let layoutMode: LayoutMode?

    enum CodingKeys: String, CodingKey {
        case name, note, position, layoutMode
        /// `parent_id` is the sole snake_case key in Workflowy request
        /// bodies; every other field is camelCase. The explicit raw value
        /// isolates that API-specified exception to this single line.
        case parent = "parent_id"
    }
}

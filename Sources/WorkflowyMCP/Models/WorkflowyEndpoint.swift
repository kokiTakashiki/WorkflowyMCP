import Foundation

/// Typed Workflowy API endpoint descriptor.
///
/// Centralizes path construction so typos are caught at the call site (via the
/// enum case name) rather than surfacing as 404s at runtime, and so a future
/// API version change only needs updates in one place.
enum WorkflowyEndpoint {
    case nodes
    case node(id: NodeID)
    case move(id: NodeID)
    case complete(id: NodeID)
    case uncomplete(id: NodeID)
    case nodesExport
    case targets

    /// Path component appended to the API base URL.
    var path: String {
        switch self {
        case .nodes: "nodes"
        case let .node(id): "nodes/\(id.rawValue)"
        case let .move(id): "nodes/\(id.rawValue)/move"
        case let .complete(id): "nodes/\(id.rawValue)/complete"
        case let .uncomplete(id): "nodes/\(id.rawValue)/uncomplete"
        case .nodesExport: "nodes-export"
        case .targets: "targets"
        }
    }
}

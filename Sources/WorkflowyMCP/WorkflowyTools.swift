import Foundation
import MCP

/// Errors raised while validating a tool call's arguments, before any
/// request to the Workflowy API reaches the network.
///
/// Declared at module scope so call sites need no enclosing-type prefix.
enum ToolCallError: LocalizedError {
    case missingArgument(ArgumentKey)
    /// Raised when the argument is present but empty or whitespace-only,
    /// which `NodeID`/`NodeParent` cannot accept.
    case blankArgument(ArgumentKey)
    case invalidEnumValue(key: ArgumentKey, value: String, allowed: [String])
    case unknownTool(name: String)

    var errorDescription: String? {
        switch self {
        case let .missingArgument(key): "必須パラメータ '\(key.rawValue)' が指定されていません。"
        case let .blankArgument(key): "必須パラメータ '\(key.rawValue)' が空または空白のみです。"
        case let .invalidEnumValue(key, value, allowed):
            "パラメータ '\(key.rawValue)' の値 '\(value)' は不正です。許可される値: \(allowed.joined(separator: ", "))"
        case let .unknownTool(name): "不明なツール: '\(name)'"
        }
    }
}

/// MCP tool surface for the Workflowy API.
///
/// `ToolKind` is the single source of tool identifiers; the JSON schemas and
/// runtime dispatch are defined as extensions in `ToolSchemas.swift` and
/// `ToolDispatch.swift`, so each tool's metadata and behavior live next to
/// code that shares their concern.
enum WorkflowyTools {
    /// Tool identifier exposed to MCP clients.
    ///
    /// `Kind` rather than `Name` because each case owns a schema definition
    /// and dispatch behavior (see extensions in `ToolSchemas.swift` /
    /// `ToolDispatch.swift`), not merely a display label. The wire-level
    /// "name" string is the `rawValue`.
    enum ToolKind: String, CaseIterable {
        case listNodes = "list_nodes"
        case getNode = "get_node"
        case createNode = "create_node"
        case updateNode = "update_node"
        case deleteNode = "delete_node"
        case moveNode = "move_node"
        case completeNode = "complete_node"
        case uncompleteNode = "uncomplete_node"
        case exportNodes = "export_nodes"
        case listTargets = "list_targets"
    }

    /// Tool schemas derived from `ToolKind.allCases`. Adding a case automatically
    /// surfaces the tool here — there is no parallel array to keep in sync.
    static let toolDefinitions: [Tool] = ToolKind.allCases.map(\.definition)

    /// Handles a single MCP tool call, converting thrown errors into an error-flagged result.
    ///
    /// This is the only MCP-boundary entry point: it looks up the tool kind,
    /// dispatches, and wraps any thrown error as `isError: true`. No separate
    /// `execute` layer sits between `handle` and `ToolKind.execute`, since the
    /// lookup is inseparable from the error-wrapping contract.
    static func handle(_ params: CallTool.Parameters, using client: WorkflowyClient) async -> CallTool.Result {
        do {
            guard let kind = ToolKind(rawValue: params.name) else {
                throw ToolCallError.unknownTool(name: params.name)
            }
            let text = try await kind.execute(arguments: params.arguments ?? [:], using: client)
            return CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
        } catch {
            return CallTool.Result(content: [.text(text: "エラー: \(error.localizedDescription)", annotations: nil, _meta: nil)], isError: true)
        }
    }
}

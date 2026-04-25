import Foundation
import MCP

extension WorkflowyTools.ToolKind {
    /// Executes the tool with the given MCP arguments and returns the text payload
    /// that should be returned to the MCP client.
    func execute(arguments: [String: Value], using client: WorkflowyClient) async throws -> String {
        let container = ToolArgumentContainer(arguments: arguments)
        switch self {
        case .listNodes:
            let parent = try NodeParent.ifPresent(decoding: .parentID, from: container)
            return try await ToolResponseEncoder.encode(client.listNodes(under: parent))

        case .getNode:
            let id = try NodeID(decoding: .id, from: container)
            return try await ToolResponseEncoder.encode(client.getNode(id: id))

        case .createNode:
            let request = try CreateNodeRequest(
                name: container.decodeStringIfPresent(forKey: .name),
                note: container.decodeStringIfPresent(forKey: .note),
                parent: NodeParent.ifPresent(decoding: .parentID, from: container),
                position: container.decodeEnumIfPresent(forKey: .position),
                layoutMode: container.decodeEnumIfPresent(forKey: .layoutMode)
            )
            return try await ToolResponseEncoder.encode(client.createNode(body: request))

        case .updateNode:
            let id = try NodeID(decoding: .id, from: container)
            let request = try UpdateNodeRequest(
                name: FieldUpdate(rawArgument: container.decodeStringIfPresent(forKey: .name)),
                note: FieldUpdate(rawArgument: container.decodeStringIfPresent(forKey: .note)),
                layoutMode: container.decodeEnumIfPresent(forKey: .layoutMode)
            )
            return try await ToolResponseEncoder.encode(client.updateNode(id: id, body: request))

        case .deleteNode:
            let id = try NodeID(decoding: .id, from: container)
            try await client.deleteNode(id: id)
            // DELETE returns no body, so there is no node snapshot to encode;
            // surface a plain-text success message instead of an empty JSON
            // object, which a client would mistake for "deleted nothing".
            return "ノード '\(id.rawValue)' を削除しました。"

        case .moveNode:
            let id = try NodeID(decoding: .id, from: container)
            let parent = try NodeParent.required(decoding: .parentID, from: container)
            let request = try MoveNodeRequest(
                parent: parent,
                position: container.decodeEnumIfPresent(forKey: .position)
            )
            return try await ToolResponseEncoder.encode(client.moveNode(id: id, body: request))

        case .completeNode:
            let id = try NodeID(decoding: .id, from: container)
            return try await ToolResponseEncoder.encode(client.completeNode(id: id))

        case .uncompleteNode:
            let id = try NodeID(decoding: .id, from: container)
            return try await ToolResponseEncoder.encode(client.uncompleteNode(id: id))

        case .exportNodes:
            return try await client.exportNodes()

        case .listTargets:
            return try await ToolResponseEncoder.encode(client.listTargets())
        }
    }
}

/// JSON encoder for MCP tool responses.
///
/// Distinct from `WorkflowyClient.encoder` (which encodes outbound request
/// bodies): this encoder is tuned for human-readable replies (pretty-printed,
/// sorted keys, seconds-since-epoch dates) and therefore must not be shared
/// with the wire-format encoder.
private enum ToolResponseEncoder {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    /// Encodes `value` into a pretty-printed JSON string.
    ///
    /// Propagates encoding errors so the surrounding handler can surface them
    /// as an MCP error result, rather than returning `"{}"` which a client
    /// would read as a successful empty payload.
    static func encode(_ value: some Encodable) throws -> String {
        let data = try encoder.encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw WorkflowyError.invalidResponse(context: "ツール応答 JSON を UTF-8 として読めません")
        }
        return text
    }
}

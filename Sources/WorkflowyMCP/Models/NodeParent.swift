import Foundation

/// Destination for a Workflowy node placement.
///
/// The API's `parent_id` field overloads three distinct meanings into a single
/// string: a node UUID, a named target key such as `"inbox"`, or the literal
/// `"None"` for top-level placement. Modeling these as a sum type keeps call
/// sites honest about which meaning they intend and rejects unrelated strings
/// at the boundary.
enum NodeParent: Equatable {
    /// Top-level placement. Serializes to the wire literal `"None"`.
    case root
    case node(NodeID)
    case target(TargetKey)

    /// Workflowy API spec: the literal string `"None"` in the `parent_id`
    /// field signals top-level placement. Centralized here so a future spec
    /// change lands in one place.
    static let rootWireValue = "None"

    /// String form expected by the Workflowy API for the `parent_id` field.
    ///
    /// Non-injective: `.node(NodeID("inbox"))` and `.target(TargetKey("inbox"))`
    /// would produce the same wire value, so callers that need round-trip
    /// fidelity must preserve the case separately rather than rely on this
    /// string alone.
    var wireValue: String {
        switch self {
        case .root: Self.rootWireValue
        case let .node(id): id.rawValue
        case let .target(key): key.rawValue
        }
    }

    /// Narrowing conversion from a wire-format / MCP-boundary `parent_id`
    /// string.
    ///
    /// Rules:
    /// - Empty or whitespace-only input → `nil` (caller raises the boundary error)
    /// - `"None"` (matching `rootWireValue`) → `.root`
    /// - A value matching a known `TargetKind` raw value → `.target`
    /// - Any other non-blank string → `.node`
    ///
    /// Non-injective with `wireValue`: `.node` and `.target` can share a wire
    /// string, so the `.target` branch is gated on `TargetKind` to avoid
    /// silently reclassifying an opaque node ID. Adding a case to `TargetKind`
    /// retroactively shifts a matching string from `.node` to `.target`;
    /// callers using opaque UUIDs will not collide in practice.
    init?(wireValue text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        if text == Self.rootWireValue {
            self = .root
            return
        }
        if TargetKind(rawValue: text) != nil, let key = TargetKey(rawValue: text) {
            self = .target(key)
            return
        }
        guard let id = NodeID(rawValue: text) else { return nil }
        self = .node(id)
    }
}

extension NodeParent: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wireValue)
    }
}

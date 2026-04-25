import Foundation

/// Wire-format adapter for `WorkflowyNode`.
///
/// The Workflowy API's JSON shape is asymmetric between responses and requests
/// (see `DataEnvelope` below), and it emits a two-field completion pair
/// (`completed` + `completedAt`) that the domain model collapses into
/// `CompletionStatus`. Keeping these concerns in an extension (isolated from
/// the domain declaration) makes `WorkflowyNode.swift` readable as a pure
/// domain type, and localizes the "why is this field re-nested?" explanation
/// to the only place that needs it.
extension WorkflowyNode: Codable {
    /// Observed API behavior: `layoutMode` appears nested under `data.layoutMode`
    /// on decode, yet is written at the top level on encode. Revisit if the API
    /// normalizes this.
    private struct DataEnvelope: Decodable {
        let layoutMode: LayoutMode?
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, note, priority, completed, createdAt, modifiedAt, completedAt
        case data
        /// Named `parent` (not `parentID`) because the Swift-side type is
        /// `NodeParent` — a sum of node UUID, target key, and root — not a
        /// bare identifier; an `ID` suffix would understate the type. Only
        /// `/nodes-export` populates this field; standard node GET responses
        /// omit the parent reference entirely.
        case parent = "parent_id"
    }

    /// Separate from `CodingKeys` because of the encode/decode asymmetry
    /// on `layoutMode`; see `DataEnvelope`.
    private enum EncodingKeys: String, CodingKey {
        case id, name, note, priority, completed, layoutMode, createdAt, modifiedAt, completedAt
        /// Mirrors `CodingKeys.parent`; see there for the naming rationale.
        case parent = "parent_id"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(NodeID.self, forKey: .id)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        // Reject an unparseable `parent_id` as data-corruption rather than
        // falling back to `nil` — a malformed wire value signals schema
        // drift, not an absent parent.
        let parentRaw = try container.decodeIfPresent(String.self, forKey: .parent)
        let parent: NodeParent?
        switch parentRaw {
        case nil:
            parent = nil
        case let raw?:
            guard let resolved = NodeParent(wireValue: raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .parent,
                    in: container,
                    debugDescription: "parent_id must be a non-empty node identifier, target key, or \"None\"."
                )
            }
            parent = resolved
        }
        let priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        // `completed` is omitted (rather than `false`) by the API for pending nodes,
        // so absence is treated as pending. `completedAt` is only meaningful when
        // `completed == true`; ignoring it otherwise prevents representing an
        // impossible pending-with-timestamp combination.
        let completedFlag = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        let completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        let completionStatus: CompletionStatus = completedFlag ? .completed(at: completedAt) : .pending
        let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        let modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt)
        let layoutMode = try container.decodeIfPresent(DataEnvelope.self, forKey: .data)?.layoutMode

        self.init(
            id: id,
            name: name,
            note: note,
            parent: parent,
            priority: priority,
            completionStatus: completionStatus,
            layoutMode: layoutMode,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(parent, forKey: .parent)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(completionStatus.isCompleted, forKey: .completed)
        try container.encodeIfPresent(layoutMode, forKey: .layoutMode)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(completionStatus.completedAt, forKey: .completedAt)
    }
}

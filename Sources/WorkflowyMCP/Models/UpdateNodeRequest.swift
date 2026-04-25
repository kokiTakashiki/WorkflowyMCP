import Foundation

/// Partial-update body for `updateNode`.
///
/// Each string field uses `FieldUpdate<String>` rather than `String?` so the
/// three operations the Workflowy API distinguishes — leave unchanged, set a
/// new value, explicitly clear — are each their own case. See `FieldUpdate`
/// for the MCP-boundary mapping and the rationale behind treating `""` as
/// the clear sentinel.
///
/// `layoutMode` stays as a plain `LayoutMode?` because the Workflowy API does
/// not expose a "clear layout mode" operation: the only two states worth
/// expressing are "set to this mode" (non-nil) and "leave unchanged" (nil),
/// so the `FieldUpdate` third case would be uninhabited.
struct UpdateNodeRequest: Encodable {
    let name: FieldUpdate<String>
    let note: FieldUpdate<String>
    let layoutMode: LayoutMode?

    enum CodingKeys: String, CodingKey {
        case name, note, layoutMode
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name.writableValue, forKey: .name)
        try container.encodeIfPresent(note.writableValue, forKey: .note)
        try container.encodeIfPresent(layoutMode, forKey: .layoutMode)
    }
}

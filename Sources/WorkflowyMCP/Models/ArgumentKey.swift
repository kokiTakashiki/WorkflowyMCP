import Foundation

/// MCP tool-call argument keys.
///
/// Owning the keys in one enum keeps the JSON schema (declared in
/// `ToolSchemas.swift`) and the dispatcher (`ToolDispatch.swift`) from
/// duplicating string literals — a typo on either side would otherwise be
/// caught only at runtime.
///
/// Raw values are the wire names sent by MCP clients; Swift-side case
/// names follow `lowerCamelCase`.
enum ArgumentKey: String {
    case id
    case name
    case note
    case parentID = "parent_id"
    case position
    case layoutMode = "layout_mode"
}

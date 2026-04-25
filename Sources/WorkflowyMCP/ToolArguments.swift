import Foundation
import MCP

/// MCP-boundary accessor over a tool call's argument dictionary.
///
/// Scope is intentionally narrow: this helper is not a generic dictionary
/// reader. It is coupled to `ToolCallError` because missing / blank /
/// unknown-enum inputs all need to surface as MCP tool-call errors, not as
/// a neutral decoding error. Method names mirror `KeyedDecodingContainer`'s
/// `decode` / `decodeIfPresent` pair so the required/optional distinction
/// is obvious at the call site.
///
/// `Container` rather than `Decoder` in the name: `Swift.Decoder` is a
/// term of art reserved for the stdlib decoding protocol, and this type
/// plays the role of a keyed container over an already-decoded dictionary.
struct ToolArgumentContainer {
    /// Raw argument dictionary from the MCP `CallTool` request, keyed by
    /// `ArgumentKey.rawValue`. Unknown keys are preserved so callers can
    /// observe them when needed rather than losing information at the boundary.
    let arguments: [String: Value]

    /// Returns the string value for `key`, throwing `missingArgument` when absent.
    func decodeString(forKey key: ArgumentKey) throws -> String {
        guard let value = arguments[key.rawValue]?.stringValue else {
            throw ToolCallError.missingArgument(key)
        }
        return value
    }

    /// Returns the string value for `key`, or `nil` when the argument is absent.
    ///
    /// Does not normalize `""` to `nil`: the empty-vs-absent distinction is
    /// load-bearing for partial-update flows (`""` means "clear this field",
    /// absent means "leave unchanged"). Callers interpret that distinction
    /// via `FieldUpdate(rawArgument:)` rather than through the raw `String?`.
    func decodeStringIfPresent(forKey key: ArgumentKey) -> String? {
        arguments[key.rawValue]?.stringValue
    }

    /// Decodes an optional enum-valued argument, throwing on unknown raw values
    /// so a typo in (e.g.) `position` is distinguishable from an omission.
    ///
    /// Named `decodeEnumIfPresent` rather than `decodeIfPresent` so the base
    /// name signals the type category, aligning with `decodeString` /
    /// `decodeStringIfPresent` in this family.
    func decodeEnumIfPresent<EnumValue: RawRepresentable & CaseIterable>(
        forKey key: ArgumentKey
    ) throws -> EnumValue? where EnumValue.RawValue == String {
        guard let raw = arguments[key.rawValue]?.stringValue else { return nil }
        guard let value = EnumValue(rawValue: raw) else {
            throw ToolCallError.invalidEnumValue(
                key: key,
                value: raw,
                allowed: EnumValue.allCases.map(\.rawValue)
            )
        }
        return value
    }
}

extension NodeID {
    /// Narrowing conversion from an MCP argument at `key` in `container` to a
    /// validated `NodeID`. Throws `missingArgument` when absent and
    /// `blankArgument` when present but empty/whitespace-only.
    ///
    /// Lives here (not on `ToolArgumentContainer`) so `NodeID` owns the
    /// "what counts as a valid node ID" invariant end-to-end — wire-format
    /// decode (`NodeID.init(from:)`) and MCP-boundary narrowing share the
    /// same non-empty rule rather than re-implementing it across layers.
    init(decoding key: ArgumentKey, from container: ToolArgumentContainer) throws {
        let raw = try container.decodeString(forKey: key)
        guard let id = NodeID(rawValue: raw) else {
            throw ToolCallError.blankArgument(key)
        }
        self = id
    }
}

extension NodeParent {
    /// Required `NodeParent` narrowed from `container[key]`.
    ///
    /// MCP-boundary wrapper over `init?(wireValue:)`: translates "argument
    /// absent" into `ToolCallError.missingArgument` and "argument present but
    /// not a valid parent reference" into `ToolCallError.blankArgument`, so
    /// callers get MCP-flavored errors rather than a neutral `Optional` miss.
    ///
    /// Paired with `ifPresent(decoding:from:)` — both are static functions so
    /// call sites read as a matching `NodeParent.required(...)` /
    /// `NodeParent.ifPresent(...)` pair at each required/optional site.
    static func required(
        decoding key: ArgumentKey,
        from container: ToolArgumentContainer
    ) throws -> NodeParent {
        let raw = try container.decodeString(forKey: key)
        guard let parent = NodeParent(wireValue: raw) else {
            throw ToolCallError.blankArgument(key)
        }
        return parent
    }

    /// Optional `NodeParent` narrowed from `container[key]` — `nil` when the
    /// argument is absent, throws `blankArgument` on an explicitly blank or
    /// unparseable value so a typo (empty string) is not silently treated as
    /// omission.
    static func ifPresent(
        decoding key: ArgumentKey,
        from container: ToolArgumentContainer
    ) throws -> NodeParent? {
        guard let raw = container.decodeStringIfPresent(forKey: key) else { return nil }
        guard let parent = NodeParent(wireValue: raw) else {
            throw ToolCallError.blankArgument(key)
        }
        return parent
    }
}

import Foundation

/// Tri-state update for a single field in a partial-update request body.
///
/// Resolves the ambiguity of a bare `Value?` where one `nil` would have to
/// encode both "caller did not touch this field" and "caller wants the field
/// cleared": those are distinct Workflowy API operations (omit the key vs.
/// send the wire-level clear sentinel), so they need distinct cases.
///
/// The encoding side (omit for `.unchanged`, value for `.set`, clear sentinel
/// for `.clear`) lives on the request type that owns the field, because the
/// clear sentinel — e.g. `""` for string fields vs. `null` for numeric ones —
/// is per-type.
enum FieldUpdate<Value: Equatable>: Equatable {
    /// Field is absent from the request body; the server preserves its value.
    case unchanged
    /// Field is present in the request body with this value.
    case set(Value)
    /// Field is explicitly cleared (the type-specific clear sentinel is sent).
    case clear
}

extension FieldUpdate where Value == String {
    /// MCP-boundary policy: absent argument means "unchanged", an explicit
    /// empty string means "clear", any other string means "set".
    ///
    /// Centralized here so every update-style tool uses the same mapping and
    /// the behavior is readable from the type rather than from the
    /// convention buried in `ToolArgumentContainer.decodeStringIfPresent`.
    init(rawArgument: String?) {
        switch rawArgument {
        case nil: self = .unchanged
        case ""?: self = .clear
        case let value?: self = .set(value)
        }
    }

    /// Value to write when the field is being sent, or `nil` when the field
    /// should be omitted from the request body entirely.
    ///
    /// Collapsing `.set(value)` and `.clear` into the same codomain is
    /// deliberate: for string fields Workflowy's "clear" signal **is** the
    /// empty string, so the wire shape is identical. The enum cases stay
    /// separate at the call site so intent ("explicitly clear") is not
    /// indistinguishable from a happens-to-be-empty value.
    var writableValue: String? {
        switch self {
        case .unchanged: nil
        case let .set(value): value
        case .clear: ""
        }
    }
}

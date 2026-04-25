import Foundation

/// Workflowy API key wrapped to keep the raw secret out of the general `String`
/// namespace.
///
/// Wrapping the key in a dedicated type lets callers pass it only where an API
/// key is expected, rejects empty strings at construction, and redacts the
/// value in log-like contexts (`description` / `debugDescription`) so an
/// accidental `print` does not leak the secret.
struct WorkflowyAPIKey: CustomStringConvertible, CustomDebugStringConvertible {
    /// The unwrapped secret. Kept private so the key cannot be pulled back out
    /// as a plain `String` from unrelated code; authorized consumers access it
    /// through a dedicated accessor (`authorizationHeaderValue`).
    private let rawValue: String

    /// Fails when `rawValue` is empty or whitespace-only; such values always
    /// produce `401 Unauthorized` and should be rejected at the boundary.
    init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.rawValue = trimmed
    }

    /// The `Authorization` header value (`"Bearer <key>"`) for Workflowy
    /// requests. Provided as a single accessor so callers never see the raw
    /// secret: there is no legitimate use of the key outside this header.
    var authorizationHeaderValue: String {
        "Bearer \(rawValue)"
    }

    var description: String {
        "<redacted>"
    }

    var debugDescription: String {
        "<redacted>"
    }
}

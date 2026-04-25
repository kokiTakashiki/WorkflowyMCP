import Foundation

/// Strongly-typed identifier for a Workflowy node; distinct from `TargetKey` by type.
///
/// Construction trims whitespace and rejects empty input, so a value of this type
/// carries the invariant "this is a non-empty Workflowy node identifier".
struct NodeID: RawRepresentable, Hashable, Codable {
    let rawValue: String

    /// Fails when `rawValue` is empty or whitespace-only. Such values would always
    /// produce 404 from the API and should be rejected at construction instead of
    /// at the network boundary.
    init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.rawValue = trimmed
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = NodeID(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "NodeID cannot be empty or whitespace-only."
            )
        }
        self = value
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

import Foundation

/// Opaque key identifying a specific Workflowy target returned by the API;
/// distinct from `NodeID` by type, and from `TargetKind` by purpose (see
/// `TargetKind` for the categorical enum). Kept as a raw `String` wrapper
/// because the API may return keys we don't yet classify.
///
/// Construction trims whitespace and rejects empty input so a value of this
/// type carries the invariant "this is a non-empty target key".
struct TargetKey: RawRepresentable, Hashable, Codable {
    let rawValue: String

    /// Fails when `rawValue` is empty or whitespace-only.
    init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.rawValue = trimmed
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = TargetKey(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "TargetKey cannot be empty or whitespace-only."
            )
        }
        self = value
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

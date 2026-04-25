import Foundation

/// A named Workflowy target such as inbox or home.
struct WorkflowyTarget: Codable {
    /// Target key (maps to API field `"key"`).
    let key: TargetKey
    let name: String?
    /// `nil` when the API omits the field or returns a value not yet known to `TargetKind`.
    let kind: TargetKind?

    enum CodingKeys: String, CodingKey {
        case key
        case name
        case kind = "type"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(TargetKey.self, forKey: .key)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        // Unknown TargetKind values collapse to nil so a future API value
        // doesn't break the whole `listTargets` response.
        kind = try? container.decodeIfPresent(TargetKind.self, forKey: .kind)
    }
}

import Foundation

/// API-defined classification of a Workflowy target, corresponding to the
/// `type` field on target responses. Distinct from `TargetKey`: `TargetKind`
/// is the closed set of known categories (e.g. `"inbox"`, `"home"`), while
/// `TargetKey` is the opaque identifier string the API uses to address a
/// specific target instance. Add cases here as the API reveals new values.
enum TargetKind: String, Codable, CaseIterable {
    case inbox
    case home
}

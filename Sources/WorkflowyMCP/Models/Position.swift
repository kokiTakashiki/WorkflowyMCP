import Foundation

/// Insertion position among a node's children.
enum Position: String, Codable, CaseIterable {
    /// First-child placement (prepend).
    case top
    /// Last-child placement (append).
    case bottom
}

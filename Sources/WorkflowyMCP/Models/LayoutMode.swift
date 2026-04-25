import Foundation

/// Display mode applied to a node's content.
enum LayoutMode: String, Codable, CaseIterable {
    case bullets
    case todo
    case h1
    case h2
    case h3
    case codeBlock = "code-block"
    case quoteBlock = "quote-block"
}

import Foundation

/// HTTP request verbs used by `WorkflowyClient`. Modeled as a closed enum so
/// the `String` value of `URLRequest.httpMethod` is built from a checked
/// source of truth rather than inline literals scattered across call sites.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

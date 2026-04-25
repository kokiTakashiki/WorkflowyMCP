import Foundation

/// Failures surfaced by `WorkflowyClient`. HTTP responses are classified by status
/// so callers can pattern-match on semantics rather than raw integers.
enum WorkflowyError: LocalizedError {
    /// The response could not be interpreted. `context` identifies the failing
    /// step (e.g. `"non-HTTP response"`, `"export body is not UTF-8"`) so the
    /// same case can cover multiple unrelated failures without collapsing
    /// diagnostics in operational logs.
    case invalidResponse(context: String)
    /// HTTP 401 — the API key is missing, expired, or invalid.
    case unauthorized(body: String)
    /// HTTP 429 — rate limit exceeded (e.g. `exportNodes` allows 1 call/minute).
    case rateLimited(body: String)
    /// HTTP 4xx other than 401/429 — request was malformed or not accepted.
    case clientError(statusCode: Int, body: String)
    /// HTTP 5xx — the server failed to process the request.
    case serverError(statusCode: Int, body: String)
    /// The API key could not be read from the Keychain.
    case missingAPIKey

    /// Classifies a non-2xx HTTP response into the matching error case.
    ///
    /// Workflowy documents stable semantics only for 401 and 429; remaining 4xx
    /// codes collapse into `.clientError` and 5xx into `.serverError`. Centralizing
    /// the mapping here so the transport layer does not have to know the policy,
    /// and so changing it (e.g. to treat 404 as a distinct case) is a single-site edit.
    init(statusCode: Int, body: String) {
        switch statusCode {
        case 401: self = .unauthorized(body: body)
        case 429: self = .rateLimited(body: body)
        case 400 ... 499: self = .clientError(statusCode: statusCode, body: body)
        default: self = .serverError(statusCode: statusCode, body: body)
        }
    }

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(context): "レスポンスが不正です: \(context)"
        case let .unauthorized(body): "認証に失敗しました (401): \(body)"
        case let .rateLimited(body): "レート制限を超えました (429): \(body)"
        case let .clientError(code, body): "HTTP \(code): \(body)"
        case let .serverError(code, body): "HTTP \(code): \(body)"
        case .missingAPIKey: "WorkflowyのAPIキーがKeychainに見つかりません。'make setup' を実行してください。"
        }
    }
}

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP client for the Workflowy public API.
struct WorkflowyClient {
    private let apiKey: WorkflowyAPIKey
    /// Root URL for every Workflowy API request.
    ///
    /// Force-unwrapped because the literal is a known-valid URL; a typo here is a
    /// programmer error that should crash at launch, not propagate as a runtime error.
    private let baseURL: URL = .init(string: "https://workflowy.com/api/v1")!
    private let session: URLSession

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private static let encoder = JSONEncoder()

    private struct NodeListResponse: Decodable { let nodes: [WorkflowyNode] }
    private struct TargetListResponse: Decodable { let targets: [WorkflowyTarget] }

    init(apiKey: WorkflowyAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Returns the children under the given parent, or the server's default
    /// listing when `parent` is `nil`.
    func listNodes(under parent: NodeParent? = nil) async throws -> [WorkflowyNode] {
        let query = parent.map { [URLQueryItem(name: "parent_id", value: $0.wireValue)] } ?? []
        let data = try await get(from: url(for: .nodes, queryItems: query))
        return try Self.decoder.decode(NodeListResponse.self, from: data).nodes
    }

    /// Returns the node with the given ID.
    func getNode(id: NodeID) async throws -> WorkflowyNode {
        let data = try await get(from: url(for: .node(id: id)))
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Creates a new node described by `body` and returns the server's representation.
    func createNode(body: CreateNodeRequest) async throws -> WorkflowyNode {
        let data = try await post(to: url(for: .nodes), body: body)
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Applies a partial update and returns the updated node.
    func updateNode(id: NodeID, body: UpdateNodeRequest) async throws -> WorkflowyNode {
        // Workflowy API uses POST for partial updates (no PATCH endpoint).
        let data = try await post(to: url(for: .node(id: id)), body: body)
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Deletes the node with the given ID.
    func deleteNode(id: NodeID) async throws {
        // Discard the returned body: DELETE responses carry no node snapshot,
        // and the transport already raises on non-2xx status.
        _ = try await delete(at: url(for: .node(id: id)))
    }

    /// Moves the node to the destination described by `body` and returns the updated node.
    func moveNode(id: NodeID, body: MoveNodeRequest) async throws -> WorkflowyNode {
        let data = try await post(to: url(for: .move(id: id)), body: body)
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Marks the node as completed and returns the updated node.
    func completeNode(id: NodeID) async throws -> WorkflowyNode {
        let data = try await postEmptyJSON(to: url(for: .complete(id: id)))
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Clears the node's completion state and returns the updated node.
    func uncompleteNode(id: NodeID) async throws -> WorkflowyNode {
        let data = try await postEmptyJSON(to: url(for: .uncomplete(id: id)))
        return try Self.decoder.decode(WorkflowyNode.self, from: data)
    }

    /// Returns the raw OPML export string. Rate-limited by the server to 1 call/minute;
    /// callers should expect `WorkflowyError.rateLimited` when exceeding that.
    func exportNodes() async throws -> String {
        let data = try await get(from: url(for: .nodesExport))
        guard let text = String(data: data, encoding: .utf8) else {
            // An empty export is a valid `""`, so a non-UTF-8 payload must be
            // surfaced as a real failure rather than collapsed to the same value.
            throw WorkflowyError.invalidResponse(context: "エクスポート本文が UTF-8 ではありません")
        }
        return text
    }

    /// Returns the list of named targets (inbox, home, ...) available to the user.
    func listTargets() async throws -> [WorkflowyTarget] {
        let data = try await get(from: url(for: .targets))
        return try Self.decoder.decode(TargetListResponse.self, from: data).targets
    }

    private func url(for endpoint: WorkflowyEndpoint, queryItems: [URLQueryItem] = []) -> URL {
        let url = baseURL.appendingPathComponent(endpoint.path)
        guard !queryItems.isEmpty else { return url }
        // Force-unwrap: `baseURL` is a valid absolute URL, so URLComponents from it
        // can never fail, and neither can building the URL back.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        return components.url!
    }

    // MARK: - HTTP verbs

    //
    // Exposed as separate methods so the type system prevents misuses like
    // attaching a body to GET/DELETE. The shared `send(...)` helper handles
    // authorization, response validation, and status-code classification.

    private func get(from url: URL) async throws -> Data {
        try await send(to: url, method: .get, body: nil)
    }

    private func post(to url: URL, body: some Encodable) async throws -> Data {
        let encoded = try Self.encoder.encode(body)
        return try await send(to: url, method: .post, body: encoded)
    }

    /// POST with an empty JSON object (`{}`). Some Workflowy endpoints (e.g.
    /// `/complete`) expect `Content-Type: application/json` even without fields.
    private func postEmptyJSON(to url: URL) async throws -> Data {
        try await send(to: url, method: .post, body: Data("{}".utf8))
    }

    private func delete(at url: URL) async throws -> Data {
        try await send(to: url, method: .delete, body: nil)
    }

    private func send(to url: URL, method: HTTPMethod, body: Data?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(apiKey.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WorkflowyError.invalidResponse(context: "HTTPURLResponse ではありません")
        }
        if (200 ... 299).contains(http.statusCode) { return data }
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        throw WorkflowyError(statusCode: http.statusCode, body: responseBody)
    }
}

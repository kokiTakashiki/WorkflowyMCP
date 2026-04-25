import Foundation
import MCP

@main
struct WorkflowyMCP {
    /// Interval between no-op wakeups that keep the process alive after
    /// `server.start(...)` returns. The exact value does not matter; the loop
    /// exists only because `@main` async context cannot use `RunLoop.main.run()`.
    ///
    /// The loop terminates when the stdio transport closes: the MCP server
    /// cancels the surrounding task, causing `Task.sleep` to throw
    /// `CancellationError`, which is caught by the enclosing `do/catch`.
    private static let keepAliveInterval: Duration = .seconds(1)

    static func main() async {
        guard let apiKey = WorkflowyAPIKeyStore.load() else {
            fputs("エラー: \(WorkflowyError.missingAPIKey.localizedDescription)\n", stderr)
            exit(1)
        }

        let client = WorkflowyClient(apiKey: apiKey)
        let server = Server(
            name: "workflowy",
            version: "1.0.0",
            capabilities: .init(tools: .init())
        )

        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: WorkflowyTools.toolDefinitions)
        }

        await server.withMethodHandler(CallTool.self) { params in
            await WorkflowyTools.handle(params, using: client)
        }

        let transport = StdioTransport()
        do {
            try await server.start(transport: transport)
            while true {
                try await Task.sleep(for: keepAliveInterval)
            }
        } catch is CancellationError {
            // Stdio transport closed — the MCP server cancelled the surrounding
            // task. This is the documented shutdown path, not a failure.
            return
        } catch {
            fputs("エラー: サーバーの起動に失敗しました: \(error)\n", stderr)
            exit(1)
        }
    }
}

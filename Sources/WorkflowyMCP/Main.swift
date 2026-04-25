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

    /// Writes `message` followed by a newline to standard error.
    ///
    /// Goes through `FileHandle.standardError` instead of `fputs(..., stderr)`
    /// because the C global `stderr` is `var`-typed shared mutable state and
    /// cannot be referenced under Swift 6 strict concurrency.
    private static func writeStderr(_ message: String) {
        guard let data = (message + "\n").data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }

    static func main() async {
        guard let apiKey = WorkflowyAPIKeyStore.load() else {
            writeStderr("エラー: \(WorkflowyError.missingAPIKey.localizedDescription)")
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
            writeStderr("エラー: サーバーの起動に失敗しました: \(error)")
            exit(1)
        }
    }
}

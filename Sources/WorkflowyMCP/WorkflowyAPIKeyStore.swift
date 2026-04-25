import Foundation

/// Retrieves the Workflowy API key from the user's macOS Keychain.
enum WorkflowyAPIKeyStore {
    private static let service = "workflowy-api-key"

    /// Returns the stored Workflowy API key, or `nil` if absent or empty.
    ///
    /// Uses `/usr/bin/security` CLI instead of `Security.framework` to avoid Keychain
    /// permission dialogs on unsigned binaries. The item is stored with `-T /usr/bin/security`;
    /// the binary is SIP-protected and cannot be tampered with (https://support.apple.com/en-us/102149).
    static func load() -> WorkflowyAPIKey? {
        guard let raw = readRawValue() else { return nil }
        return WorkflowyAPIKey(rawValue: raw)
    }

    /// Reads the raw Keychain entry. Returns `nil` for any failure (missing item,
    /// non-zero exit code, non-UTF-8 payload). Normalization (trim, empty check)
    /// is delegated to `WorkflowyAPIKey.init(rawValue:)`.
    private static func readRawValue() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", service, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

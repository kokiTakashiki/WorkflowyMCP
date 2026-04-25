# WorkflowyMCP

A [Model Context Protocol](https://modelcontextprotocol.io) server for the [Workflowy API](https://workflowy.com/api-reference/), written in Swift.

## Prerequisites

- macOS 13+
- Swift 6.0+
- [Homebrew](https://brew.sh)
- [1Password CLI](https://developer.1password.com/docs/cli/) with desktop app integration enabled
- Workflowy API key stored in 1Password

## Setup

```bash
make setup
```

This will:
1. Install [Mint](https://github.com/yonaskolb/Mint), [Genesis](https://github.com/yonaskolb/Genesis), and [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
2. Run Genesis interactively — you will be prompted for:
   - Your 1Password item path (e.g. `op://Vault/Item/Field`)
   - The binary install directory (default: `/usr/local/bin`)
3. Generate `config.mk` and `claude-desktop-config.json` locally (both gitignored)
4. Fetch your Workflowy API key from 1Password and store it in macOS Keychain

## Build

```bash
make build
# Binary: .build/release/WorkflowyMCP
```

CI builds on every push and pull request to `main` using the official `swift:6.2-jammy` container on Ubuntu. The source compiles on Linux (API key loading from macOS Keychain is a no-op there), but the server is only supported for runtime use on macOS.

## Claude Desktop Integration

`make generate` produces a `claude-desktop-config.json` snippet. Copy its contents into your Claude Desktop config file at:

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### Example configuration

```json
{
  "mcpServers": {
    "workflowy": {
      "command": "/usr/local/bin/WorkflowyMCP"
    }
  }
}
```

If you haven't installed the binary to a permanent location yet, you can point directly to the build output for a quick trial:

```json
{
  "mcpServers": {
    "workflowy": {
      "command": "/path/to/WorkflowyMCP/.build/release/WorkflowyMCP"
    }
  }
}
```

After editing the config, restart Claude Desktop. The `workflowy` server will appear in the MCP tools list.

## API Key Management

| Command | Description |
|---|---|
| `make setup` | Fetch API key from 1Password and store in Keychain |
| `make check-credentials` | Verify the API key is present in Keychain |
| `make reset-credentials` | Remove the API key from Keychain |

The API key is stored as a generic password in macOS Keychain under service name `workflowy-api-key`. It is never written to disk as plaintext.

Your 1Password item path is stored in `config.mk` (gitignored) and never committed to the repository.

## Available Tools

| Tool | Description |
|---|---|
| `list_nodes` | List child nodes of a parent |
| `get_node` | Get a node by ID |
| `create_node` | Create a new node |
| `update_node` | Update an existing node |
| `delete_node` | Delete a node |
| `move_node` | Move a node to a new parent |
| `complete_node` | Mark a node as completed |
| `uncomplete_node` | Unmark a completed node |
| `export_nodes` | Export all nodes (rate limit: 1 req/min) |
| `list_targets` | List available targets (inbox, home, etc.) |

## Other Commands

```bash
make generate   # Regenerate config.mk and claude-desktop-config.json
make format     # Format Swift source files
make upgrade    # Upgrade development tools
make help       # Show all available commands
```

## Trademarks & Disclaimer

- "Workflowy" and the Workflowy logo are trademarks of WorkFlowy, Inc.
- This project is an unofficial, third-party client and is not affiliated with, endorsed by, or sponsored by WorkFlowy, Inc.
- Each user must supply their own Workflowy API key. No API credentials are bundled with this repository.

## Acknowledgments

- The [Model Context Protocol](https://modelcontextprotocol.io/) developer community
- [Workflowy](https://workflowy.com/) and the [Workflowy API](https://workflowy.com/api-reference/)


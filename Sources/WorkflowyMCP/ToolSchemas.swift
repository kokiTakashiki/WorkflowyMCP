import Foundation
import MCP

/// JSON schema keys used when assembling MCP tool descriptors.
private enum SchemaKey {
    static let type = "type"
    static let properties = "properties"
    static let required = "required"
    static let enumValues = "enum"
    static let description = "description"
}

/// JSON schema type names used in MCP tool descriptors.
private enum SchemaType {
    static let object = "object"
    static let string = "string"
}

/// Reusable property descriptions so the same parameter text does not drift
/// between tools (e.g. the `parent_id` accepted by `listNodes` / `createNode`).
private enum PropertyDescription {
    static let parentIdWithTargetsAndRoot =
        "親ノードのID、ターゲットキー（'inbox'/'home'）、または 'None'（ルート）。省略時はルートを返します。"
    static let parentIdWithTargetsAndRootRequired =
        "親ノードのID、ターゲットキー（'inbox'/'home'）、または 'None'"
    static let insertPosition = "挿入位置"
}

/// Builders for JSON schema fragments used in MCP tool descriptors.
///
/// Grouped under a single namespace so call sites read as
/// `SchemaFragment.string(description:)` / `.object(properties:required:)`,
/// per Swift API Design Guidelines' preference for methods over free
/// functions when an obvious `self` exists.
private enum SchemaFragment {
    /// Builds a JSON schema fragment for a single string-typed property.
    static func string(description: String) -> Value {
        .object([
            SchemaKey.type: .string(SchemaType.string),
            SchemaKey.description: .string(description),
        ])
    }

    /// Builds a JSON schema fragment for a property constrained to a string enum.
    static func stringEnum<E: CaseIterable & RawRepresentable>(
        of _: E.Type,
        description: String
    ) -> Value where E.RawValue == String {
        .object([
            SchemaKey.type: .string(SchemaType.string),
            SchemaKey.enumValues: .array(E.allCases.map { .string($0.rawValue) }),
            SchemaKey.description: .string(description),
        ])
    }

    /// Builds a top-level JSON object schema with the given properties and required keys.
    ///
    /// `properties` accepts a dictionary literal for concise call sites while
    /// still forbidding duplicate keys at construction time: repeating an
    /// `ArgumentKey` is treated as a programmer error and traps via
    /// `Dictionary(uniqueKeysWithValues:)`.
    static func object(
        properties: KeyValuePairs<ArgumentKey, Value>,
        required: [ArgumentKey] = []
    ) -> Value {
        var dict: [String: Value] = [
            SchemaKey.type: .string(SchemaType.object),
            SchemaKey.properties: .object(
                Dictionary(uniqueKeysWithValues: properties.map { ($0.key.rawValue, $0.value) })
            ),
        ]
        if !required.isEmpty {
            dict[SchemaKey.required] = .array(required.map { .string($0.rawValue) })
        }
        return .object(dict)
    }
}

extension WorkflowyTools.ToolKind {
    /// JSON schema descriptor reported to MCP clients via `list_tools`.
    ///
    /// - Complexity: Allocates a fresh schema dictionary on each call.
    var definition: Tool {
        switch self {
        case .listNodes:
            Tool(
                name: rawValue,
                description: "子ノードの一覧を取得します",
                inputSchema: SchemaFragment.object(properties: [
                    .parentID: SchemaFragment.string(description: PropertyDescription.parentIdWithTargetsAndRoot),
                ])
            )
        case .getNode:
            Tool(
                name: rawValue,
                description: "指定IDのノードを取得します",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "ノードのID"),
                    ],
                    required: [.id]
                )
            )
        case .createNode:
            Tool(
                name: rawValue,
                description: "新しいノードを作成します",
                inputSchema: SchemaFragment.object(properties: [
                    .name: SchemaFragment.string(description: "ノードのテキスト内容（Markdown/HTML書式対応）"),
                    .note: SchemaFragment.string(description: "ノードのメモ"),
                    .parentID: SchemaFragment.string(description: PropertyDescription.parentIdWithTargetsAndRootRequired),
                    .position: SchemaFragment.stringEnum(of: Position.self, description: PropertyDescription.insertPosition),
                    .layoutMode: SchemaFragment.stringEnum(of: LayoutMode.self, description: "表示モード"),
                ])
            )
        case .updateNode:
            Tool(
                name: rawValue,
                description: "既存のノードを更新します",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "更新するノードのID"),
                        .name: SchemaFragment.string(description: "新しいテキスト内容"),
                        .note: SchemaFragment.string(description: "新しいメモ"),
                        .layoutMode: SchemaFragment.stringEnum(of: LayoutMode.self, description: "新しい表示モード"),
                    ],
                    required: [.id]
                )
            )
        case .deleteNode:
            Tool(
                name: rawValue,
                description: "ノードを削除します",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "削除するノードのID"),
                    ],
                    required: [.id]
                )
            )
        case .moveNode:
            Tool(
                name: rawValue,
                description: "ノードを別の親ノードに移動します",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "移動するノードのID"),
                        .parentID: SchemaFragment.string(description: PropertyDescription.parentIdWithTargetsAndRootRequired),
                        .position: SchemaFragment.stringEnum(of: Position.self, description: PropertyDescription.insertPosition),
                    ],
                    required: [.id, .parentID]
                )
            )
        case .completeNode:
            Tool(
                name: rawValue,
                description: "ノードを完了済みにマークします",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "完了にするノードのID"),
                    ],
                    required: [.id]
                )
            )
        case .uncompleteNode:
            Tool(
                name: rawValue,
                description: "ノードの完了状態を解除します",
                inputSchema: SchemaFragment.object(
                    properties: [
                        .id: SchemaFragment.string(description: "完了解除するノードのID"),
                    ],
                    required: [.id]
                )
            )
        case .exportNodes:
            Tool(
                name: rawValue,
                description: "全ノードをエクスポートします（レート制限: 1回/分）",
                inputSchema: SchemaFragment.object(properties: [:])
            )
        case .listTargets:
            Tool(
                name: rawValue,
                description: "利用可能なターゲット（inbox, home など）の一覧を取得します",
                inputSchema: SchemaFragment.object(properties: [:])
            )
        }
    }
}

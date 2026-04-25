.PHONY: help setup upgrade build format analyze generate check-credentials reset-credentials _setup-credentials

# ローカル設定（make generate で生成、gitignore済み）
-include config.mk

KEYCHAIN_SERVICE := workflowy-api-key

# デフォルトターゲット - ヘルプの表示
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup              - 開発環境のセットアップとAPIキーの登録を行います"
	@echo "  make build              - リリースビルドします（swift build -c release）"
	@echo "  make generate           - GenesisでローカルのMakefile設定とClaude Desktop設定ファイルを生成します"
	@echo "  make format             - SwiftFormatでコードをフォーマットします"
	@echo "  make analyze            - Peripheryで未使用コードを静的解析します"
	@echo "  make upgrade            - 開発環境ツールをアップグレードします"
	@echo "  make check-credentials  - KeychainにAPIキーが存在するか確認します"
	@echo "  make reset-credentials  - KeychainからAPIキーを削除します"
	@echo "  make help               - このヘルプを表示します"

# 開発環境のセットアップ（ツールインストール + Genesis生成 + APIキー設定）
setup:
	@echo "開発環境をセットアップしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。https://brew.sh を参照してください。" && exit 1)
	@if ! which mint > /dev/null 2>&1; then \
		echo "Mintをインストール中..."; \
		brew install mint; \
	else \
		echo "Mintは既にインストール済み"; \
	fi
	@echo "Genesisをインストール中..."
	@mint install yonaskolb/Genesis
	@if ! which swiftformat > /dev/null 2>&1; then \
		echo "SwiftFormatをインストール中..."; \
		brew install swiftformat; \
	else \
		echo "SwiftFormatは既にインストール済み"; \
	fi
	@if ! which periphery > /dev/null 2>&1; then \
		echo "Peripheryをインストール中..."; \
		brew install peripheryapp/periphery/periphery; \
	else \
		echo "Peripheryは既にインストール済み"; \
	fi
	@if ! which swiftly > /dev/null 2>&1; then \
		echo "swiftlyをインストール中..."; \
		brew install swiftly; \
		swiftly init --quiet-shell-followup --assume-yes; \
	else \
		echo "swiftlyは既にインストール済み"; \
	fi
	@echo "最新のSwiftツールチェーンをインストール中..."
	@swiftly install --use latest
	@if [ ! -f config.mk ]; then \
		$(MAKE) generate; \
	else \
		echo "config.mkは既に存在します（スキップ）。再生成は 'make generate' で実行できます。"; \
	fi
	@$(MAKE) _setup-credentials
	@echo "セットアップが完了しました！"
	@echo ""
	@echo "次のステップ:"
	@echo "  1. シェルを開き直す（または 'source ~/.swiftly/env.sh' を実行）してswiftlyのPATHを反映する"
	@echo "  2. 'make build' でバイナリをビルドする"
	@echo "  3. claude-desktop-config.json の内容をClaude Desktopの設定に追加する"

_setup-credentials:
	@[ -n "$(OP_ITEM_PATH)" ] || (echo "OP_ITEM_PATHが未設定です。'make generate' を先に実行してください。" && exit 1)
	@echo "1PasswordからWorkflowy APIキーを取得しています..."
	@which op > /dev/null 2>&1 || (echo "1Password CLIがインストールされていません。https://1password.com/downloads/command-line/ を参照してください。" && exit 1)
	@API_KEY=$$(op read "$(OP_ITEM_PATH)") && \
		security add-generic-password \
			-U \
			-a "$$USER" \
			-s "$(KEYCHAIN_SERVICE)" \
			-T /usr/bin/security \
			-w "$$API_KEY" && \
		echo "Keychainにサービス '$(KEYCHAIN_SERVICE)' として保存しました。"

# リリースビルド（実行ファイルは .build/release/WorkflowyMCP）
# swiftlyを使用している場合は env.sh を読み込んで PATH を通す
build:
	@. $$HOME/.swiftly/env.sh 2>/dev/null; swift build -c release

# GenesisでローカルのMakefile設定とClaude Desktop設定ファイルを生成
generate:
	@echo "Genesisで設定ファイルを生成しています..."
	@which mint > /dev/null 2>&1 || (echo "Mintがインストールされていません。'make setup' を実行してください。" && exit 1)
	mint run yonaskolb/Genesis genesis generate genesis.yml
	@echo "config.mk と claude-desktop-config.json を生成しました。"

# SwiftFormatの実行
format:
	@if ! which swiftformat > /dev/null 2>&1; then \
		echo "SwiftFormatがインストールされていません。'make setup' を実行してください。"; \
		exit 1; \
	fi
	swiftformat Sources/

# Peripheryで未使用コードを静的解析
analyze:
	@if ! which periphery > /dev/null 2>&1; then \
		echo "Peripheryがインストールされていません。'make setup' を実行してください。"; \
		exit 1; \
	fi
	periphery scan --disable-update-check --strict

# 開発環境ツールのアップグレード
upgrade:
	@echo "開発環境ツールをアップグレードしています..."
	@which brew > /dev/null 2>&1 || (echo "Homebrewがインストールされていません。" && exit 1)
	@if which mint > /dev/null 2>&1; then \
		echo "Mintをアップグレード中..."; \
		brew upgrade mint || true; \
	else \
		echo "Mintがインストールされていません。'make setup' を実行してください。"; \
	fi
	@if which mint > /dev/null 2>&1; then \
		echo "Genesisをアップグレード中..."; \
		mint install yonaskolb/Genesis; \
	fi
	@if which swiftformat > /dev/null 2>&1; then \
		echo "SwiftFormatをアップグレード中..."; \
		brew upgrade swiftformat || true; \
	else \
		echo "SwiftFormatがインストールされていません。'make setup' を実行してください。"; \
	fi
	@if which periphery > /dev/null 2>&1; then \
		echo "Peripheryをアップグレード中..."; \
		brew upgrade periphery || true; \
	else \
		echo "Peripheryがインストールされていません。'make setup' を実行してください。"; \
	fi
	@if which swiftly > /dev/null 2>&1; then \
		echo "swiftly本体をアップグレード中..."; \
		brew upgrade swiftly || true; \
		echo "Swiftツールチェーンを最新に更新中..."; \
		swiftly install --use latest; \
	else \
		echo "swiftlyがインストールされていません。'make setup' を実行してください。"; \
	fi
	@echo "アップグレードが完了しました！"

# KeychainにAPIキーが存在するか確認（値は表示しない）
check-credentials:
	@security find-generic-password -s "$(KEYCHAIN_SERVICE)" >/dev/null 2>&1 && \
		echo "OK: '$(KEYCHAIN_SERVICE)' はKeychainに存在します。" || \
		echo "NG: '$(KEYCHAIN_SERVICE)' はKeychainに存在しません。'make setup' を実行してください。"

# KeychainからAPIキーを削除（マシン手放し・デバッグ時に使用）
reset-credentials:
	@security delete-generic-password -s "$(KEYCHAIN_SERVICE)" 2>/dev/null && \
		echo "'$(KEYCHAIN_SERVICE)' をKeychainから削除しました。" || \
		echo "'$(KEYCHAIN_SERVICE)' はKeychainに存在しません（既にクリーンです）。"

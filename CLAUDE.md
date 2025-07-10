# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コマンド

### 開発
- `npm start` - ローカル開発サーバーをホットリロード付きで起動（Functions Framework使用）
- `npm run build` - esbuildを使用して本番用バンドルをビルド
- `npm run check-types` - TypeScriptの型チェックを実行

### テスト
- `npm test` - Jestで全テストを実行
- `npm run auth-test` - 認証機能のテストを実行
- テストファイルは `/test` ディレクトリに配置され、`@/` エイリアスでsrcをインポート

### デプロイ
- インフラ: `cd terraform && terraform apply`
- モジュール化されたTerraform設定を `terraform/modules/` で管理
- Google Cloudプロジェクト: `advent-calendar-2024-w`
- リージョン: `asia-northeast1`
- カスタムドメイン: `api.tenkawa-k.com`

## アーキテクチャ

Google Cloud Functionsを使用したサーバーレスHTTPエンドポイントの実装で、高度なGCP機能を活用しています。

### コード構造
- **TypeScript + ESM**: モダンなES modulesとTypeScriptを使用
- **エントリーポイント**: `src/index.ts` がメインのHTTP関数をエクスポート
- **認証**: `src/auth.ts` でGoogle Cloud認証を処理
- **ビルドプロセス**: カスタム `build.ts` がesbuildで最適化されたバンドルを作成
- **モジュールエイリアス**: `@/` が `src/` ディレクトリにマップ

### インフラストラクチャコンポーネント
各GCPサービスごとにTerraformモジュールを使用:
- **functions/**: dist/からのソースでCloud Functionsをデプロイ
- **endpoints/**: API管理用のCloud Endpoints設定
- **gateway/**: ルーティング用のESP v2を使用したAPI Gateway
- **scheduler/**: 定期的な関数実行のためのCloud Scheduler
- **secret/**: Secret Manager設定

### 主要なアーキテクチャ上の決定
1. **ESMファースト**: ES moduleとして設定し、esbuildでCommonJS互換性を確保
2. **本番最適化**: 最小限のランタイム依存関係のための別のprod-package.json
3. **API Gateway**: ESP v2（Extensible Service Proxy）バージョン2.51.0を使用
4. **認証**: 認証付きCloud Function呼び出しのビルトインサポート
5. **モジュール化されたインフラ**: 各GCPサービスが独自のTerraformモジュールを持つ

### 開発ワークフロー
1. `src/` でコード変更を行う
2. `npm start` でホットリロード付きのローカルテスト
3. `npm test` でテストが通ることを確認
4. デプロイ前に `npm run build` でビルド
5. `terraform/` ディレクトリでTerraformを使用してインフラ変更をデプロイ
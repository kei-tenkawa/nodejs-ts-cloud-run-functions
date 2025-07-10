# nodejs-ts-cloud-run-functions

TypeScript 対応の Google Run functions を使用したサーバーレスアプリケーションのサンプルプロジェクトです。Cloud Endpoints による独自ドメイン設定、認証付きアクセス、定期実行などの実装例を含んでいます。<br/>
詳細は以下のQiitaのアドベントカレンダーにて説明しております。<br/>
[Cloud Run functions × TypeScript 開発をしよう！ Advent Calendar 2024](https://qiita.com/advent-calendar/2024/cloud-run-functions-typescript)

## 📋 目次

- [概要](#概要)
- [アーキテクチャ](#アーキテクチャ)
- [前提条件](#前提条件)
- [セットアップ](#セットアップ)
- [開発](#開発)
- [デプロイ](#デプロイ)
- [テスト](#テスト)
- [プロジェクト構成](#プロジェクト構成)
- [トラブルシューティング](#トラブルシューティング)

## 概要

このプロジェクトは、Google Cloud Platform (GCP) 上でサーバーレスアプリケーションを構築するためのテンプレートです。以下の機能を実装しています：

- **Cloud Run functions**: Node.js 20ランタイムでのHTTP関数
- **認証機能**: Google Cloud IDトークンによる認証付きアクセス
- **独自ドメイン**: Cloud EndpointsとESPv2による独自ドメイン設定
- **定期実行**: Cloud Schedulerによる定期的な関数実行
- **シークレット管理**: Secret Managerによる機密情報の安全な管理
- **Infrastructure as Code**: Terraformによるインフラ管理

## アーキテクチャ

```
インターネット
    ↓
[独自ドメイン (ここではapi.tenkawa-k.com)]
    ↓
[Cloud Run (ESPv2 Gateway)]
    ↓
[Cloud Run functions]
    ↑
[Cloud Scheduler] (定期実行)
```

## 前提条件

### 必要なツール

- Node.js 20.11.0以上
- npm 10.x以上
- Terraform 1.0以上
- Google Cloud SDK (gcloud CLI)
- Git

### GCPの設定

1. GCPプロジェクトの作成
2. 以下のAPIを有効化：
   ```bash
   gcloud services enable cloudfunctions.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable cloudscheduler.googleapis.com
   gcloud services enable secretmanager.googleapis.com
   gcloud services enable endpoints.googleapis.com
   gcloud services enable storage.googleapis.com
   ```

3. 適切な権限を持つサービスアカウントの設定

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/nodejs-ts-cloud-run-functions.git
cd nodejs-ts-cloud-run-functions
```

### 2. 依存関係のインストール

```bash
npm install
```

### 3. 環境変数の設定

`.env.yml.example` をコピーして `.env.yml` を作成：

```bash
cp .env.yml.example .env.yml
```

以下の内容を編集：

```yaml
REGION: asia-northeast1
PROJECT: your-gcp-project-id
AUTH_FUNC: sample-crf
```

### 4. Terraformの初期化

```bash
cd terraform
terraform init
```

`main.tf` の `locals` ブロックを環境に合わせて編集：

```hcl
locals {
  project         = "your-gcp-project-id"
  region          = "asia-northeast1"
  zone            = "asia-northeast1-a"
  domain          = "your-domain.com"  # 独自ドメインを使用する場合
  ESPv2_image_ver = "2.51.0"
}
```

## 開発

### ローカル開発サーバーの起動

```bash
npm start
```

Functions Frameworkが起動し、http://localhost:8080 でアクセス可能になります。
ファイルの変更は自動的に検出され、ホットリロードされます。

### 利用可能なnpmスクリプト

| コマンド | 説明 |
|---------|------|
| `npm start` | 開発サーバーをホットリロード付きで起動 |
| `npm run auth-test` | 認証機能のテスト実行 |
| `npm run check-types` | TypeScriptの型チェック |
| `npm run build` | 本番用ビルドの作成 |
| `npm test` | Jestテストの実行 |

### コード構成

```
src/
├── index.ts        # メインのHTTP関数エントリーポイント
├── auth.ts         # 認証機能の実装
└── hoge/
    └── hoge.ts     # サンプル関数
```

### 新しい関数の追加

1. `src/index.ts` に新しい関数をエクスポート：

```typescript
export const myNewFunction: HttpFunction = async (req: ff.Request, res: ff.Response) => {
  // 実装
};
```

2. `terraform/modules/functions/main.tf` のエントリーポイントを更新

## デプロイ

### 1. アプリケーションのビルド

```bash
npm run build
```

### 2. Terraformでのインフラデプロイ

```bash
cd terraform
terraform plan
terraform apply
```

### 3. 独自ドメインの設定（オプション）

Cloud Endpointsを使用する場合は、DNSレコードの設定が必要です：

1. `terraform apply` 実行後に表示されるCloud RunのIPアドレスを確認
2. ドメインプロバイダーでAレコードを設定

## テスト

### ユニットテストの実行

```bash
npm test
```

### カバレッジレポートの確認

テスト実行後、`coverage/lcov-report/index.html` をブラウザで開いてカバレッジを確認できます。

### 認証テスト

デプロイ後の認証機能をテストするには：

```bash
npm run auth-test
```

## プロジェクト構成

```
.
├── src/                    # ソースコード
│   ├── index.ts           # メインエントリーポイント
│   ├── auth.ts            # 認証機能
│   └── hoge/              # 機能モジュール
├── test/                   # テストファイル
├── terraform/              # Terraformモジュール
│   ├── main.tf            # メイン設定
│   └── modules/           # 各種モジュール
│       ├── functions/     # Cloud Functions
│       ├── secret/        # Secret Manager
│       ├── endpoints/     # Cloud Endpoints
│       ├── gateway/       # Cloud Run (ESPv2)
│       └── scheduler/     # Cloud Scheduler
├── dist/                   # ビルド成果物
├── coverage/               # テストカバレッジ
├── package.json           # Node.js設定
├── tsconfig.json          # TypeScript設定
├── jest.config.js         # Jest設定
└── .github/               # GitHub Actions設定
    └── workflows/
        └── test.yml       # CI/CDパイプライン
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. ビルドエラー

```bash
npm run check-types  # 型エラーの確認
```

#### 2. デプロイエラー

- GCPのAPIが有効化されているか確認
- サービスアカウントの権限を確認
- Terraformのステートファイルが正しいか確認

#### 3. 認証エラー

- `.env.yml` の設定が正しいか確認
- サービスアカウントに必要なIAMロールが付与されているか確認

### ログの確認

```bash
# Cloud Functionsのログ
gcloud functions logs read sample-crf --region=asia-northeast1

# Cloud Runのログ
gcloud run logs read gateway --region=asia-northeast1
```

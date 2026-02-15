# Journaly
日記アプリケーション

## 技術スタック

- **フロントエンド**: Next.js 16 + React 19 + TypeScript + Tailwind CSS
- **バックエンド**: NestJS + Prisma
- **データベース**: PostgreSQL 16
- **開発ツール**: Task (Taskfile.yml)

## 必要な環境

- Node.js 20以上
- Docker & Docker Compose
- [Task](https://taskfile.dev/) - タスクランナー

### Taskのインストール

```bash
# macOS (Homebrew)
brew install go-task

# または、公式サイトからインストール
# https://taskfile.dev/installation/
```

## 環境構築手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd Journaly
```

### 2. 環境変数の設定

環境変数ファイルを作成します：

```bash
# バックエンド用
cp journaly-backend/.env.example journaly-backend/.env

# フロントエンド用
cp journaly-frontend/.env.example journaly-frontend/.env.local
```

デフォルトの設定で問題なければ、そのまま使用できます。

**バックエンド (journaly-backend/.env):**
```env
DATABASE_URL="postgresql://journaly:journaly@localhost:5432/journaly"
PORT=3001
```

**フロントエンド (journaly-frontend/.env.local):**
```env
NEXT_PUBLIC_API_URL=http://localhost:3001
```

### 3. 初回セットアップ

```bash
# 全ての依存関係をインストール + データベースセットアップ + マイグレーション実行
task setup
```

このコマンドは以下を自動で実行します：
- バックエンドとフロントエンドの依存関係インストール
- PostgreSQLコンテナの起動
- Prismaクライアントの生成
- データベースマイグレーションの実行

### 4. 開発サーバーの起動

```bash
task dev
```

以下のサービスが起動します：
- データベース: `localhost:5432`
- バックエンド: `http://localhost:3001`
- フロントエンド: `http://localhost:3000`

### 5. 開発サーバーの停止

```bash
# 別のターミナルで実行
task stop
```

または、`task dev` を実行しているターミナルで `Ctrl+C` を押してください。

## 利用可能なTaskコマンド

### 基本コマンド

| コマンド | 説明 |
|---------|------|
| `task setup` | 初回セットアップ（依存関係 + DB + マイグレーション） |
| `task dev` | 開発環境を起動（DB + バックエンド + フロントエンド） |
| `task stop` | 全てのサービスを停止 |
| `task clean` | データベースを含めて全てクリーンアップ |
| `task install` | 全ての依存関係をインストール |

### 個別サービス起動

| コマンド | 説明 |
|---------|------|
| `task db` | データベースのみ起動 |
| `task backend` | バックエンドのみ起動 |
| `task frontend` | フロントエンドのみ起動 |

### データベース関連

| コマンド | 説明 |
|---------|------|
| `task generate` | Prismaクライアントを生成 |
| `task migrate` | マイグレーションを実行（開発環境） |
| `task migrate:deploy` | マイグレーションを実行（本番環境） |
| `task prisma:studio` | Prisma Studioを起動 |
| `task db:stop` | データベースを停止 |
| `task db:logs` | データベースのログを表示 |

## プロジェクト構成

```
Journaly/
├── docker-compose.yml          # PostgreSQLコンテナ定義
├── Taskfile.yml                # タスク定義
├── journaly-backend/           # NestJSバックエンド
│   ├── prisma/
│   │   └── schema.prisma       # Prismaスキーマ定義
│   └── src/
│       ├── journals/           # 日記機能
│       ├── users/              # ユーザー機能
│       └── prisma/             # Prismaサービス
└── journaly-frontend/          # Next.jsフロントエンド
    ├── app/
    │   ├── dashboard/          # ダッシュボード
    │   ├── signin/             # サインイン
    │   └── signup/             # サインアップ
    └── lib/
```

## データベース接続情報

開発環境のデータベース接続情報：

```
Host: localhost
Port: 5432
User: journaly
Password: journaly
Database: journaly
```

Prisma接続文字列:
```
DATABASE_URL="postgresql://journaly:journaly@localhost:5432/journaly"
```

バックエンドAPIポート: `3001`

## トラブルシューティング

### ポートがすでに使用されている

```bash  # フロントエンド
lsof -i :3001  # バックエンド
lsof -i :5432  # データベース
lsof -i :3000
lsof -i :5432

# プロセスを停止
task stop
```

### データベースをリセットしたい

```bash
# データベースを削除して再作成
task clean
task setup
```

### Prismaクライアントのエラー

```bash
# Prismaクライアントを再生成
task generate
```

## 開発のヒント1` でアクセス可能
- フロントエンドは `http://localhost:3000

- 開発中はホットリロードが有効です
- バックエンドのAPIは `http://localhost:3000/api` でアクセス可能
- データベースの内容を確認するには `task prisma:studio` を実行
- マイグレーションファイルは `journaly-backend/prisma/migrations/` に保存されます

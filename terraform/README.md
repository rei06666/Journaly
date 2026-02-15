# Journaly AWS Infrastructure

このディレクトリにはJournalyアプリケーションをAWSにデプロイするためのTerraformコードが含まれています。

## アーキテクチャ

### バックエンド (ECS Fargate)
- **ECS Cluster**: Fargateでバックエンドアプリケーションを実行
- **ADOT Collector**: サイドカーコンテナとして動作し、トレースとメトリクスを収集
- **Application Load Balancer**: HTTPSトラフィックを受け付け、ECSタスクにルーティング
- **Auto Scaling**: CPU/メモリ使用率に基づいて自動スケーリング

### フロントエンド (S3 + CloudFront)
- **S3 Bucket**: Next.jsの静的エクスポートファイルをホスト
- **CloudFront**: グローバルCDNで高速配信

### データベース (RDS PostgreSQL)
- **RDS PostgreSQL**: マネージドデータベースサービス
- **Multi-AZ**: 本番環境では高可用性構成
- **Automated Backups**: 自動バックアップと復旧

### 監視 (CloudWatch & Application Signals)
- **CloudWatch Logs**: アプリケーションログの集約
- **CloudWatch Alarms**: リソース使用率の監視とアラート
- **Application Signals**: 分散トレーシングとサービスマップ
- **X-Ray**: リクエストトレーシング

## 前提条件

1. AWS CLIのインストールと設定
```bash
aws configure
```

2. Terraformのインストール (>= 1.9)
```bash
brew install terraform
```

3. Dockerのインストール（コンテナイメージのビルド用）

## デプロイ手順

### 1. Terraform初期化

```bash
cd terraform
terraform init
```

### 2. 変数ファイルの作成

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`を編集して、必要な値を設定してください。

### 3. インフラストラクチャのプランニング

```bash
terraform plan
```

### 4. インフラストラクチャのデプロイ

```bash
terraform apply
```

デプロイには10-15分程度かかります。

### 5. バックエンドのDockerイメージビルドとプッシュ

```bash
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com

# バックエンドイメージをビルド
cd ../journaly-backend
docker build -t journaly-dev-backend .

# タグ付け
docker tag journaly-dev-backend:latest <ECR_REPOSITORY_URL>:latest

# プッシュ
docker push <ECR_REPOSITORY_URL>:latest
```

### 6. ECSサービスの更新

```bash
aws ecs update-service --cluster journaly-dev-cluster --service journaly-dev-backend-service --force-new-deployment --region ap-northeast-1
```

### 7. データベースマイグレーション

```bash
# ECSタスクでマイグレーションを実行
aws ecs run-task \
  --cluster journaly-dev-cluster \
  --task-definition journaly-dev-backend \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --overrides '{"containerOverrides": [{"name": "backend", "command": ["npx", "prisma", "migrate", "deploy"]}]}'
```

### 8. フロントエンドのデプロイ

```bash
cd ../journaly-frontend

# 環境変数の設定
export NEXT_PUBLIC_API_URL=http://<ALB_DNS_NAME>

# ビルド（静的エクスポート）
npm run build
npm run export  # または next.config.tsでoutput: 'export'を設定

# S3にアップロード
aws s3 sync out/ s3://journaly-dev-frontend --delete

# CloudFrontのキャッシュをクリア
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

## 出力

デプロイ後、以下の情報が出力されます：

```bash
terraform output
```

- `alb_dns_name`: バックエンドAPIのエンドポイント
- `cloudfront_domain_name`: フロントエンドのURL
- `backend_ecr_repository_url`: バックエンドのECRリポジトリURL
- `rds_endpoint`: データベースエンドポイント（機密情報）

## 監視とログ

### CloudWatch Logs
```bash
# バックエンドログの確認
aws logs tail /ecs/journaly-dev/backend --follow

# ADOTログの確認
aws logs tail /ecs/journaly-dev/adot --follow
```

### CloudWatch Dashboard
AWSコンソール → CloudWatch → Dashboards → `journaly-dev-dashboard`

### Application Signals
AWSコンソール → CloudWatch → Application Signals

## クリーンアップ

リソースを削除する場合：

```bash
# S3バケットを空にする
aws s3 rm s3://journaly-dev-frontend --recursive

# ECRイメージを削除
aws ecr batch-delete-image --repository-name journaly-dev-backend --image-ids imageTag=latest

# Terraformで削除
terraform destroy
```

## コスト見積もり（月額・東京リージョン）

- **VPC & ネットワーク**: ~$30-50（NATゲートウェイ）
- **ECS Fargate**: ~$15-30（0.25 vCPU, 0.5GB RAM, 1タスク）
- **Application Load Balancer**: ~$20-25
- **RDS t4g.micro**: ~$15-20
- **S3 + CloudFront**: ~$5-10（トラフィック次第）
- **CloudWatch**: ~$5-10

**合計: 約$90-145/月**

開発環境でコストを削減するには：
- `single_nat_gateway = true`（すでに設定済み）
- `backend_desired_count = 1`（すでに設定済み）
- 夜間/週末にリソースを停止

## トラブルシューティング

### ECSタスクが起動しない
1. CloudWatch Logsでエラーを確認
2. タスク定義のIAMロールを確認
3. セキュリティグループの設定を確認

### データベース接続エラー
1. セキュリティグループでポート5432が許可されているか確認
2. Secrets Managerにパスワードが正しく保存されているか確認
3. DATABASE_URL環境変数が正しいか確認

### フロントエンドが表示されない
1. S3にファイルがアップロードされているか確認
2. CloudFrontのキャッシュをクリア
3. CloudFrontのOrigin設定を確認

## セキュリティのベストプラクティス

✅ すでに実装済み：
- VPCでプライベートサブネット使用
- セキュリティグループで最小限のアクセス
- RDSの暗号化
- S3のパブリックアクセスブロック
- CloudFrontでHTTPSリダイレクト
- IAMロールの最小権限
- Secrets Managerでパスワード管理

## 次のステップ

1. **カスタムドメインの設定**: Route 53とACM証明書
2. **CI/CD パイプライン**: GitHub ActionsやCodePipeline
3. **バックアップ戦略**: RDSスナップショットの定期取得
4. **WAFの追加**: CloudFrontにWAFを追加
5. **コスト最適化**: Reserved InstancesやSavings Plans

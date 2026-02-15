# データベースマイグレーション手順

## 自動実行（推奨）

**アプリケーション起動時に自動実行**

バックエンドコンテナは起動時に自動的に`npx prisma migrate deploy`を実行してからアプリケーションを起動します。

デプロイフロー：
1. GitHub Actionsで新しいDockerイメージをビルド
2. ECRにプッシュ
3. ECSサービスを更新
4. 新しいコンテナ起動時にmigrationが自動実行
5. migration成功後にアプリケーションが起動

migrationが失敗した場合、コンテナは起動せず、ECSはヘルスチェック失敗としてロールバックします。

## 手動でmigrationを実行する方法（緊急時）

### 方法1: ECS Execを使う

初回デプロイ後、または緊急時に手動でmigrationを実行する場合：

```bash
# 環境変数を設定
export AWS_PROFILE=journaly-terraform-admin
export ENVIRONMENT=dev  # または prod

# ECS Execを有効にする（初回のみ必要）
aws ecs update-service \
  --cluster journaly-${ENVIRONMENT}-cluster \
  --service journaly-${ENVIRONMENT}-backend-service \
  --enable-execute-command \
  --region ap-northeast-1

# 実行中のタスクIDを取得
TASK_ARN=$(aws ecs list-tasks \
  --cluster journaly-${ENVIRONMENT}-cluster \
  --service-name journaly-${ENVIRONMENT}-backend-service \
  --desired-status RUNNING \
  --region ap-northeast-1 \
  --query 'taskArns[0]' \
  --output text)

echo "Task ARN: $TASK_ARN"

# コンテナに接続してmigrationを実行
aws ecs execute-command \
  --cluster journaly-${ENVIRONMENT}-cluster \
  --task $TASK_ARN \
  --container backend \
  --interactive \
  --command "/bin/sh" \
  --region ap-northeast-1
```

コンテナ内で：
```bash
# migrationを実行
npx prisma migrate deploy

# 実行状態を確認
npx prisma migrate status

# 終了
exit
```

### 方法2: AWS CLIでRun Taskを使う

```bash
# 環境変数を設定
export AWS_PROFILE=journaly-terraform-admin
export ENVIRONMENT=dev  # または prod
export AWS_REGION=ap-northeast-1

# サービスからVPC設定を取得
SERVICE_INFO=$(aws ecs describe-services \
  --cluster journaly-${ENVIRONMENT}-cluster \
  --services journaly-${ENVIRONMENT}-backend-service \
  --region $AWS_REGION)

SUBNETS=$(echo $SERVICE_INFO | jq -r '.services[0].networkConfiguration.awsvpcConfiguration.subnets | @csv' | tr -d '"')
SECURITY_GROUPS=$(echo $SERVICE_INFO | jq -r '.services[0].networkConfiguration.awsvpcConfiguration.securityGroups | @csv' | tr -d '"')

# Migration taskを実行
aws ecs run-task \
  --cluster journaly-${ENVIRONMENT}-cluster \
  --task-definition journaly-${ENVIRONMENT}-backend \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUPS],assignPublicIp=DISABLED}" \
  --overrides '{
    "containerOverrides": [
      {
        "name": "backend",
        "command": ["sh", "-c", "npx prisma migrate deploy && echo Migration completed successfully"]
      }
    ]
  }' \
  --region $AWS_REGION
```

## Prisma Studioでデータを確認する

ローカルからRDSに接続してPrisma Studioを使用する場合：

```bash
# RDSのエンドポイントとパスワードをSecrets Managerから取得
DB_SECRET_ARN=$(aws secretsmanager list-secrets \
  --query "SecretList[?contains(Name, 'journaly-${ENVIRONMENT}-db')].ARN" \
  --output text \
  --region ap-northeast-1)

DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --region ap-northeast-1 \
  --query SecretString \
  --output text)

DB_HOST=$(echo $DB_SECRET | jq -r '.host')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

# DATABASE_URLを設定
export DATABASE_URL="postgresql://journalyapp:${DB_PASSWORD}@${DB_HOST}:5432/journalydb"

# ローカルから接続（VPNまたはSSH踏み台経由が必要）
npx prisma studio
```

## トラブルシューティング

### Migrationが失敗する場合

1. **データベース接続を確認**
   ```bash
   # ECS Execでコンテナ内から確認
   echo $DATABASE_URL
   ```

2. **セキュリティグループを確認**
   - ECSタスクのセキュリティグループからRDSへのアクセスが許可されているか確認

3. **Migrationの状態を確認**
   ```bash
   npx prisma migrate status
   ```

4. **ログを確認**
   ```bash
   aws logs tail /ecs/journaly-${ENVIRONMENT}/backend --follow --region ap-northeast-1
   ```

### ECS Execが使えない場合

Terraformで`enable_execute_command = true`が設定されているか確認：

```bash
# terraform/backend.tf を確認
grep -A 5 "enable_execute_command" terraform/backend.tf
```

設定されていない場合は、Terraformファイルを更新してデプロイ：

```hcl
resource "aws_ecs_service" "backend" {
  # ...
  enable_execute_command = true
  # ...
}
```

## ベストプラクティス

1. **本番環境でのmigration**
   - 必ずdev環境で先にテストする
   - ピークタイム外に実行する
   - バックアップを取得してから実行する
   - ロールバック計画を準備する

2. **Migration履歴の管理**
   - `prisma/migrations/`ディレクトリをGitで管理する
   - Migration履歴は削除しない

3. **データロスを防ぐ**
   - カラム削除やテーブル削除の前にデータを確認
   - 必要に応じて2段階migration（データ移行→スキーマ変更）

4. **モニタリング**
   - Migration実行時のログを確認
   - 実行時間を記録する
   - エラーが発生した場合は即座に対応する

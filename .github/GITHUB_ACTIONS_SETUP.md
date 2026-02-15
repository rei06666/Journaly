# GitHub Actions 環境変数とSecrets設定ガイド

## 必須のRepository Secrets

GitHubリポジトリ → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret名 | 説明 | 取得方法 |
|---------|------|---------|
| `AWS_ROLE_ARN` | GitHub Actions用のAWS IAMロールARN | `terraform output github_actions_role_arn` |

### AWS_ROLE_ARN の取得方法

```bash
cd terraform
terraform output github_actions_role_arn
```

出力例: `arn:aws:iam::699475923389:role/journaly-dev-github-actions-role`

---

## Environment Secrets（オプション）

環境ごとに異なる設定を使う場合は、Environmentsで管理します。

GitHubリポジトリ → **Settings** → **Environments** → **New environment**

### dev 環境

| Secret名 | 値の例 |
|---------|--------|
| `AWS_ROLE_ARN` | `arn:aws:iam::699475923389:role/journaly-dev-github-actions-role` |

### prod 環境

| Secret名 | 値の例 |
|---------|--------|
| `AWS_ROLE_ARN` | `arn:aws:iam::699475923389:role/journaly-prod-github-actions-role` |

---

## ワークフローで使用される環境変数

これらは `.github/workflows/*.yml` ファイルに既に設定されています。

### デプロイ全体で共通

```yaml
env:
  AWS_REGION: ap-northeast-1
```

### Terraformワークフロー

```yaml
env:
  AWS_REGION: ap-northeast-1
  TERRAFORM_VERSION: 1.9.0
```

### バックエンドデプロイワークフロー

```yaml
env:
  AWS_REGION: ap-northeast-1
  ECR_REPOSITORY: journaly-dev-backend  # environmentに応じて変化
```

### フロントエンドデプロイワークフロー

```yaml
env:
  AWS_REGION: ap-northeast-1
  NODE_VERSION: '20'
```

---

## 設定手順

### Step 1: Terraformを実行してロールを作成

```bash
cd terraform
terraform apply

# ロールARNを取得
terraform output github_actions_role_arn
```

### Step 2: GitHubにSecretを設定

#### Repository Secretsの場合

1. GitHubリポジトリのページを開く
2. **Settings** タブをクリック
3. 左メニューから **Secrets and variables** → **Actions** をクリック
4. **New repository secret** をクリック
5. 以下を入力:
   - **Name**: `AWS_ROLE_ARN`
   - **Secret**: `arn:aws:iam::699475923389:role/journaly-dev-github-actions-role`
6. **Add secret** をクリック

#### Environment Secretsの場合（dev/prodで分ける）

1. GitHubリポジトリのページを開く
2. **Settings** タブをクリック
3. 左メニューから **Environments** をクリック
4. **New environment** をクリックして `dev` を作成
5. **Add secret** をクリック
6. 以下を入力:
   - **Name**: `AWS_ROLE_ARN`
   - **Value**: `arn:aws:iam::699475923389:role/journaly-dev-github-actions-role`
7. 同様に `prod` 環境も作成

### Step 3: 動作確認

1. GitHubリポジトリの **Actions** タブをクリック
2. **Deploy Infrastructure (Terraform)** を選択
3. **Run workflow** をクリック
4. Environment: `dev`, Action: `plan` を選択
5. **Run workflow** をクリック
6. 実行ログを確認

---

## セキュリティのベストプラクティス

### ✅ 推奨事項

1. **Environment Protection Rules** を設定
   - Settings → Environments → dev/prod
   - **Required reviewers** を追加（本番環境のみ）
   - **Wait timer** を設定（本番環境のみ）

2. **ブランチ保護ルール** を設定
   - Settings → Branches → Add rule
   - Branch name pattern: `main`
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging

3. **Secrets scanning** を有効化
   - Settings → Code security and analysis
   - ✅ Secret scanning

### ⚠️ 注意事項

- `AWS_ROLE_ARN` は機密情報として扱う
- AWS Access KeyやSecret Keyは**使用しない**（OIDCを使用）
- Secretsはログに出力されない（`${{ secrets.AWS_ROLE_ARN }}`）
- 環境変数はログに出力される可能性がある

---

## トラブルシューティング

### エラー: "Could not assume role"

**原因**: IAMロールの信頼ポリシーでリポジトリ名が間違っている

**解決方法**:
```hcl
# terraform/variables.tf
variable "github_repo" {
  default     = "your-username/Journaly"  # ← 正しいリポジトリ名に変更
}
```

```bash
terraform apply
```

### エラー: "Secrets not found"

**原因**: Secret名が間違っている、または設定されていない

**解決方法**:
1. Settings → Secrets and variables → Actions で確認
2. Secret名が `AWS_ROLE_ARN` であることを確認
3. 値が正しいARN形式であることを確認

### エラー: "Access Denied"

**原因**: IAMロールに必要な権限がない

**解決方法**:
```bash
# ロールにAdministratorAccessが付与されているか確認
aws iam list-attached-role-policies \
  --role-name journaly-dev-github-actions-role
```

---

## クイックリファレンス

### 設定するSecrets（最小構成）

```
AWS_ROLE_ARN = arn:aws:iam::699475923389:role/journaly-dev-github-actions-role
```

### ワークフロー実行コマンド（手動）

```bash
# Terraform Plan
Actions → Deploy Infrastructure (Terraform) → Run workflow
  Environment: dev
  Action: plan

# Backend Deploy
Actions → Deploy Backend to ECS → Run workflow
  Environment: dev

# Frontend Deploy
Actions → Deploy Frontend to S3 + CloudFront → Run workflow
  Environment: dev
```

### 自動デプロイトリガー

- `terraform/` への変更 → Terraform plan（自動）
- `journaly-backend/` への変更 → Backend deploy（自動）
- `journaly-frontend/` への変更 → Frontend deploy（自動）

---

## 参考リンク

- [GitHub Actions - Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions - Using environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [AWS - Configuring OIDC in GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

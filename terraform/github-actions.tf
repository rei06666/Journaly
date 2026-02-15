# GitHub Actions OIDC Provider
# Note: This will fail if the provider already exists. In that case, import it:
# terraform import aws_iam_openid_connect_provider.github_actions arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]

  tags = {
    Name = "github-actions-oidc-provider"
  }

  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-${var.environment}-github-actions-role"
  description = "Role for GitHub Actions to deploy ${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-github-actions-role"
  }
}

# Attach AdministratorAccess policy to GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

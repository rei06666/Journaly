# Import AWS-managed RDS master user secret
data "aws_secretsmanager_secret" "rds_master_secret" {
  arn = module.rds.db_instance_master_user_secret_arn
}

data "aws_secretsmanager_secret_version" "rds_master_secret" {
  secret_id = data.aws_secretsmanager_secret.rds_master_secret.id
}

# RDS PostgreSQL Module
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-${var.environment}-postgres"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2

  db_name  = var.db_name
  username = var.db_username
  manage_master_user_password = true
  port     = 5432

  multi_az               = var.environment == "prod" ? true : false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Backups
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Enhanced Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Encryption
  storage_encrypted = true

  # Deletion protection
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"
  final_snapshot_identifier_prefix = "${var.project_name}-${var.environment}-final"

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}
# Create a custom secret with DATABASE_URL for ECS
locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds_master_secret.secret_string)
  database_url = "postgresql://${urlencode(local.rds_secret.username)}:${urlencode(local.rds_secret.password)}@${module.rds.db_instance_address}:5432/${var.db_name}"
}

resource "aws_secretsmanager_secret" "db_connection" {
  name                    = "${var.project_name}-${var.environment}-db-connection"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-db-connection"
  }
}

resource "aws_secretsmanager_secret_version" "db_connection" {
  secret_id = aws_secretsmanager_secret.db_connection.id
  secret_string = jsonencode({
    database_url = local.database_url
  })
}

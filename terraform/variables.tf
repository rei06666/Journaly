variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "journaly"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # 最小のインスタンスクラス（Free Tier対象）
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "journaly"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "journaly_admin"
  sensitive   = true
}

# ECS Variables
variable "backend_cpu" {
  description = "CPU units for backend container"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory for backend container in MB"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "backend_container_port" {
  description = "Backend container port"
  type        = number
  default     = 3001
}

# Frontend Variables
variable "frontend_domain_name" {
  description = "Domain name for frontend (optional)"
  type        = string
  default     = ""
}

# Monitoring Variables
variable "enable_application_signals" {
  description = "Enable AWS Application Signals"
  type        = bool
  default     = true
}

# GitHub Actions Variables
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' for OIDC authentication"
  type        = string
  default     = "rei06666/Journaly"
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "journaly-terraform-state"
}

variable "terraform_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

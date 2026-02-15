terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "journaly-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Journaly"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

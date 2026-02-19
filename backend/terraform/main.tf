# ============================================================================
# Supplier Cheque Management & Cash Flow ML System - Main Configuration
# ============================================================================
# Senior Cloud Engineer Best Practices:
# - Modular design with separate files per service
# - Environment-agnostic with variables
# - Least privilege IAM policies
# - Encryption at rest and in transit
# - Cost optimization with on-demand billing
# - Comprehensive tagging for cost allocation
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cheque-management/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ChequeManagement"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Owner       = var.owner_email
    }
  }
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Naming convention: {project}-{environment}-{service}
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Lambda runtime configuration
  lambda_runtime = "nodejs18.x"
  lambda_timeout = 30
  lambda_memory  = 512

  # API Gateway stage name
  api_stage_name = var.environment
}

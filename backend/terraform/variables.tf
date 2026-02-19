# ============================================================================
# Variables - Environment Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cheque-mgmt"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "Finance"
}

variable "owner_email" {
  description = "Email of the system owner"
  type        = string
  default     = "admin@example.com"
}

# ============================================================================
# Cognito Configuration
# ============================================================================

variable "cognito_password_minimum_length" {
  description = "Minimum password length for Cognito users"
  type        = number
  default     = 8
}

variable "cognito_mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"
}

# ============================================================================
# DynamoDB Configuration
# ============================================================================

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB"
  type        = bool
  default     = true
}

# ============================================================================
# S3 Configuration
# ============================================================================

variable "s3_lifecycle_glacier_days" {
  description = "Days before transitioning objects to Glacier"
  type        = number
  default     = 365
}

variable "s3_lifecycle_expiration_days" {
  description = "Days before expiring objects (0 = never)"
  type        = number
  default     = 0
}

# ============================================================================
# Lambda Configuration
# ============================================================================

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# ============================================================================
# API Gateway Configuration
# ============================================================================

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}

# ============================================================================
# EventBridge Configuration
# ============================================================================

variable "reminder_schedule_expression" {
  description = "Cron expression for daily reminder (UTC)"
  type        = string
  default     = "cron(0 9 * * ? *)" # 9 AM UTC daily
}

variable "forecast_schedule_expression" {
  description = "Cron expression for weekly ML forecast (UTC)"
  type        = string
  default     = "cron(0 2 ? * SUN *)" # 2 AM UTC every Sunday
}

# ============================================================================
# SES Configuration
# ============================================================================

variable "ses_sender_email" {
  description = "Verified sender email for SES"
  type        = string
  default     = "noreply@example.com"
}

variable "ses_configuration_set_name" {
  description = "SES configuration set name"
  type        = string
  default     = "cheque-management-emails"
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "cloudwatch_alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
  default     = "alerts@example.com"
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for Lambdas"
  type        = bool
  default     = true
}

# ============================================================================
# CORS Configuration
# ============================================================================

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["http://localhost:5173", "http://localhost:3000"]
}

variable "cors_allowed_methods" {
  description = "Allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}

# ============================================================================
# Additional Configuration Variables
# ============================================================================

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (leave empty to skip)"
  type        = string
  default     = ""
}

variable "notification_email" {
  description = "Email address to receive notifications"
  type        = string
  default     = ""
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 2000
}

variable "api_quota_limit" {
  description = "API Gateway daily quota limit"
  type        = number
  default     = 100000
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Cheque Management System"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

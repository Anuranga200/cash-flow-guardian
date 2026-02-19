# ============================================================================
# Outputs - Resource Information for Integration
# ============================================================================

# ============================================================================
# Cognito Outputs
# ============================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web_client.id
  sensitive   = true
}

output "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

# ============================================================================
# API Gateway Outputs
# ============================================================================

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_root_resource_id" {
  description = "API Gateway root resource ID"
  value       = aws_api_gateway_rest_api.main.root_resource_id
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = "${aws_api_gateway_deployment.main.invoke_url}${aws_api_gateway_stage.main.stage_name}"
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.main.stage_name
}

# ============================================================================
# DynamoDB Outputs
# ============================================================================

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.main.arn
}

# ============================================================================
# S3 Outputs
# ============================================================================

output "s3_bucket_name" {
  description = "S3 bucket name for cheque images and reports"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

# ============================================================================
# SNS Outputs
# ============================================================================

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = aws_sns_topic.cheque_reminders.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.cheque_reminders.name
}

# ============================================================================
# Lambda Outputs
# ============================================================================

output "lambda_functions" {
  description = "Map of Lambda function names to ARNs"
  value = {
    cheques       = aws_lambda_function.cheques.arn
    suppliers     = aws_lambda_function.suppliers.arn
    bank_accounts = aws_lambda_function.bank_accounts.arn
    notifications = aws_lambda_function.notifications.arn
    reports       = aws_lambda_function.reports.arn
    forecasts     = aws_lambda_function.forecasts.arn
    textract      = aws_lambda_function.textract_processor.arn
    reminders     = aws_lambda_function.reminder_scheduler.arn
    ml_forecast   = aws_lambda_function.ml_forecast.arn
  }
}

# ============================================================================
# EventBridge Outputs
# ============================================================================

output "eventbridge_reminder_rule_arn" {
  description = "EventBridge rule ARN for daily reminders"
  value       = aws_cloudwatch_event_rule.daily_reminder.arn
}

output "eventbridge_forecast_rule_arn" {
  description = "EventBridge rule ARN for weekly ML forecast"
  value       = aws_cloudwatch_event_rule.weekly_forecast.arn
}

# ============================================================================
# CloudWatch Outputs
# ============================================================================

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    cheques       = aws_cloudwatch_log_group.cheques.name
    suppliers     = aws_cloudwatch_log_group.suppliers.name
    bank_accounts = aws_cloudwatch_log_group.bank_accounts.name
    notifications = aws_cloudwatch_log_group.notifications.name
    reports       = aws_cloudwatch_log_group.reports.name
    forecasts     = aws_cloudwatch_log_group.forecasts.name
    textract      = aws_cloudwatch_log_group.textract_processor.name
    reminders     = aws_cloudwatch_log_group.reminder_scheduler.name
    ml_forecast   = aws_cloudwatch_log_group.ml_forecast.name
  }
}

# ============================================================================
# Environment Configuration Output
# ============================================================================

output "environment_config" {
  description = "Environment configuration for frontend integration"
  value = {
    region              = var.aws_region
    environment         = var.environment
    cognito_user_pool   = aws_cognito_user_pool.main.id
    cognito_client_id   = aws_cognito_user_pool_client.web_client.id
    api_endpoint        = "${aws_api_gateway_deployment.main.invoke_url}${aws_api_gateway_stage.main.stage_name}"
    dynamodb_table      = aws_dynamodb_table.main.name
    s3_bucket           = aws_s3_bucket.main.id
  }
  sensitive = true
}

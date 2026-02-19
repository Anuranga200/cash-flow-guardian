# ============================================================================
# API Gateway REST API
# ============================================================================
# Purpose: REST API with Cognito JWT authorizer for all backend endpoints
# Best Practice: Use REST API for request/response pattern, separate resources
# ============================================================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "Cheque Management System API - ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"] # REGIONAL is recommended for single-region deployments
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-api-${var.environment}"
    }
  )
}

# ============================================================================
# Cognito Authorizer
# ============================================================================
# Purpose: JWT token validation before Lambda invocation
# Best Practice: Validate tokens at API Gateway level, not in Lambda
# ============================================================================

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.project_name}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"

  provider_arns = [
    aws_cognito_user_pool.main.arn
  ]
}

# ============================================================================
# API Gateway Resources (URL paths)
# ============================================================================

# /v1 base path
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "v1"
}

# /v1/cheques
resource "aws_api_gateway_resource" "cheques" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "cheques"
}

# /v1/cheques/{chequeId}
resource "aws_api_gateway_resource" "cheque_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.cheques.id
  path_part   = "{chequeId}"
}

# /v1/cheques/{chequeId}/upload-url
resource "aws_api_gateway_resource" "cheque_upload" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.cheque_id.id
  path_part   = "upload-url"
}

# /v1/cheques/{chequeId}/status
resource "aws_api_gateway_resource" "cheque_status" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.cheque_id.id
  path_part   = "status"
}

# /v1/suppliers
resource "aws_api_gateway_resource" "suppliers" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "suppliers"
}

# /v1/suppliers/{supplierId}
resource "aws_api_gateway_resource" "supplier_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.suppliers.id
  path_part   = "{supplierId}"
}

# /v1/bank-accounts
resource "aws_api_gateway_resource" "bank_accounts" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "bank-accounts"
}

# /v1/bank-accounts/{accountId}
resource "aws_api_gateway_resource" "bank_account_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bank_accounts.id
  path_part   = "{accountId}"
}

# /v1/bank-accounts/{accountId}/transactions
resource "aws_api_gateway_resource" "bank_transactions" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bank_account_id.id
  path_part   = "transactions"
}

# /v1/notifications
resource "aws_api_gateway_resource" "notifications" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "notifications"
}

# /v1/notifications/{notificationId}
resource "aws_api_gateway_resource" "notification_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.notifications.id
  path_part   = "{notificationId}"
}

# /v1/notifications/{notificationId}/read
resource "aws_api_gateway_resource" "notification_read" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.notification_id.id
  path_part   = "read"
}

# /v1/reports
resource "aws_api_gateway_resource" "reports" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "reports"
}

# /v1/reports/export
resource "aws_api_gateway_resource" "reports_export" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.reports.id
  path_part   = "export"
}

# /v1/forecasts
resource "aws_api_gateway_resource" "forecasts" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "forecasts"
}

# /v1/forecasts/{dateRange}
resource "aws_api_gateway_resource" "forecast_date" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.forecasts.id
  path_part   = "{dateRange}"
}

# ============================================================================
# CORS Configuration
# ============================================================================
# Purpose: Enable frontend to call API from different origin
# Best Practice: Explicit CORS headers, restrict origins in production
# ============================================================================

module "cors_cheques" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.cheques.id
}

module "cors_suppliers" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.suppliers.id
}

module "cors_bank_accounts" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bank_accounts.id
}

module "cors_notifications" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.notifications.id
}

module "cors_reports" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.reports.id
}

module "cors_forecasts" {
  source = "./modules/cors"

  api_id      = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.forecasts.id
}

# ============================================================================
# API Gateway Deployment
# ============================================================================
# Purpose: Deploy API to a stage
# Best Practice: Use stage variables for environment-specific config
# ============================================================================

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Force redeployment when any method changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.main.body,
      aws_api_gateway_resource.v1.id,
      aws_api_gateway_resource.cheques.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    # Add all method dependencies here after creating Lambda integrations
  ]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  # Enable CloudWatch logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  # Enable X-Ray tracing
  xray_tracing_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-api-stage-${var.environment}"
    }
  )
}

# ============================================================================
# CloudWatch Log Group for API Gateway
# ============================================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# API Gateway Account Settings (for CloudWatch logging)
# ============================================================================

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# ============================================================================
# Method Settings (Throttling, Caching, Metrics)
# ============================================================================

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch metrics
    metrics_enabled = true
    logging_level   = "INFO"

    # Enable detailed CloudWatch metrics
    data_trace_enabled = var.environment != "prod" # Only in non-prod

    # Throttling settings
    throttling_burst_limit = var.api_throttle_burst_limit
    throttling_rate_limit  = var.api_throttle_rate_limit

    # Caching (disabled by default, enable if needed)
    caching_enabled = false
  }
}

# ============================================================================
# Usage Plan and API Key (Optional - for rate limiting)
# ============================================================================

resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.project_name}-usage-plan-${var.environment}"
  description = "Usage plan for ${var.project_name} API"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  quota_settings {
    limit  = var.api_quota_limit
    period = "DAY"
  }

  throttle_settings {
    burst_limit = var.api_throttle_burst_limit
    rate_limit  = var.api_throttle_rate_limit
  }

  tags = var.common_tags
}

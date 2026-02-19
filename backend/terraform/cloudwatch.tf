# ============================================================================
# CloudWatch Alarms and Monitoring
# ============================================================================
# Purpose: Proactive monitoring and alerting for system health
# Best Practice: Monitor key metrics, set appropriate thresholds
# ============================================================================

# ============================================================================
# Lambda Error Alarms
# ============================================================================
# Purpose: Alert when Lambda functions have high error rates
# Threshold: > 5% error rate in 5 minutes
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_cheques_errors" {
  alarm_name          = "${var.project_name}-lambda-cheques-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300" # 5 minutes
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Cheques Lambda has more than 5 errors in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.cheques.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_suppliers_errors" {
  alarm_name          = "${var.project_name}-lambda-suppliers-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Suppliers Lambda has more than 5 errors in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.suppliers.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_bank_accounts_errors" {
  alarm_name          = "${var.project_name}-lambda-bank-accounts-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Bank Accounts Lambda has more than 5 errors in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.bank_accounts.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# Lambda Throttle Alarms
# ============================================================================
# Purpose: Alert when Lambda functions are being throttled
# Indicates need for concurrency limit increase
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_cheques_throttles" {
  alarm_name          = "${var.project_name}-lambda-cheques-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when Cheques Lambda is throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.cheques.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# API Gateway Error Alarms
# ============================================================================
# Purpose: Alert on API Gateway 5xx errors
# Threshold: > 10 errors in 5 minutes
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when API Gateway has more than 10 5xx errors in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  alarm_name          = "${var.project_name}-api-4xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100" # Higher threshold for client errors
  alarm_description   = "Alert when API Gateway has more than 100 4xx errors in 10 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# API Gateway Latency Alarm
# ============================================================================
# Purpose: Alert when API response time is too high
# Threshold: > 2000ms average latency
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  alarm_name          = "${var.project_name}-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000" # 2 seconds
  alarm_description   = "Alert when API Gateway latency exceeds 2 seconds"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# DynamoDB Throttle Alarms
# ============================================================================
# Purpose: Alert when DynamoDB requests are being throttled
# Indicates need for capacity adjustment
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-read-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB read requests are throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-write-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB write requests are throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# DynamoDB Consumed Capacity Alarms (for provisioned mode)
# ============================================================================
# Note: Only relevant if switching from on-demand to provisioned billing
# ============================================================================

# resource "aws_cloudwatch_metric_alarm" "dynamodb_read_capacity" {
#   alarm_name          = "${var.project_name}-dynamodb-read-capacity-${var.environment}"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "ConsumedReadCapacityUnits"
#   namespace           = "AWS/DynamoDB"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "80" # 80% of provisioned capacity
#   alarm_description   = "Alert when DynamoDB read capacity exceeds 80%"
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     TableName = aws_dynamodb_table.main.name
#   }
#
#   alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
#
#   tags = var.common_tags
# }

# ============================================================================
# Textract Lambda Errors
# ============================================================================
# Purpose: Monitor OCR processing failures
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "textract_lambda_errors" {
  alarm_name          = "${var.project_name}-textract-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Textract Lambda has errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.textract_processor.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# Reminder Scheduler Errors
# ============================================================================
# Purpose: Monitor daily reminder job failures
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "reminder_scheduler_errors" {
  alarm_name          = "${var.project_name}-reminder-scheduler-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "3600" # 1 hour (runs daily)
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when Reminder Scheduler fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.reminder_scheduler.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# ML Forecast Errors
# ============================================================================
# Purpose: Monitor weekly ML forecast job failures
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "ml_forecast_errors" {
  alarm_name          = "${var.project_name}-ml-forecast-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when ML Forecast job fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.ml_forecast.function_name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# CloudWatch Dashboard
# ============================================================================
# Purpose: Centralized view of system metrics
# Best Practice: Single pane of glass for monitoring
# ============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Cheques" }],
            ["...", { stat = "Sum", label = "Suppliers" }],
            ["...", { stat = "Sum", label = "Bank Accounts" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Invocations"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { stat = "Sum" }],
            [".", "Throttles", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Errors & Throttles"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum" }],
            [".", "4XXError", { stat = "Sum" }],
            [".", "5XXError", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Requests"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity"
        }
      }
    ]
  })
}

# ============================================================================
# IAM Roles and Policies - Least Privilege Access
# ============================================================================
# Best Practices:
# - Separate IAM role per Lambda function
# - Least privilege permissions
# - Managed policies where appropriate
# - Custom policies for specific access patterns
# ============================================================================

# ============================================================================
# Lambda Execution Role - Base Policy
# ============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# Cheques Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_cheques" {
  name               = "${local.name_prefix}-lambda-cheques-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_cheques_basic" {
  role       = aws_iam_role.lambda_cheques.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_cheques_dynamodb" {
  name = "${local.name_prefix}-lambda-cheques-dynamodb"
  role = aws_iam_role.lambda_cheques.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          aws_dynamodb_table.main.arn,
          "${aws_dynamodb_table.main.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_cheques_s3" {
  name = "${local.name_prefix}-lambda-cheques-s3"
  role = aws_iam_role.lambda_cheques.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_cheques_xray" {
  name = "${local.name_prefix}-lambda-cheques-xray"
  role = aws_iam_role.lambda_cheques.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Suppliers Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_suppliers" {
  name               = "${local.name_prefix}-lambda-suppliers-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_suppliers_basic" {
  role       = aws_iam_role.lambda_suppliers.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_suppliers_dynamodb" {
  name = "${local.name_prefix}-lambda-suppliers-dynamodb"
  role = aws_iam_role.lambda_suppliers.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_suppliers_xray" {
  name = "${local.name_prefix}-lambda-suppliers-xray"
  role = aws_iam_role.lambda_suppliers.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Bank Accounts Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_bank_accounts" {
  name               = "${local.name_prefix}-lambda-bank-accounts-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_bank_accounts_basic" {
  role       = aws_iam_role.lambda_bank_accounts.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_bank_accounts_dynamodb" {
  name = "${local.name_prefix}-lambda-bank-accounts-dynamodb"
  role = aws_iam_role.lambda_bank_accounts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_bank_accounts_xray" {
  name = "${local.name_prefix}-lambda-bank-accounts-xray"
  role = aws_iam_role.lambda_bank_accounts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Notifications Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_notifications" {
  name               = "${local.name_prefix}-lambda-notifications-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_notifications_basic" {
  role       = aws_iam_role.lambda_notifications.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_notifications_dynamodb" {
  name = "${local.name_prefix}-lambda-notifications-dynamodb"
  role = aws_iam_role.lambda_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_notifications_xray" {
  name = "${local.name_prefix}-lambda-notifications-xray"
  role = aws_iam_role.lambda_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Reports Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_reports" {
  name               = "${local.name_prefix}-lambda-reports-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_reports_basic" {
  role       = aws_iam_role.lambda_reports.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_reports_dynamodb" {
  name = "${local.name_prefix}-lambda-reports-dynamodb"
  role = aws_iam_role.lambda_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_reports_s3" {
  name = "${local.name_prefix}-lambda-reports-s3"
  role = aws_iam_role.lambda_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_reports_xray" {
  name = "${local.name_prefix}-lambda-reports-xray"
  role = aws_iam_role.lambda_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Forecasts Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_forecasts" {
  name               = "${local.name_prefix}-lambda-forecasts-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_forecasts_basic" {
  role       = aws_iam_role.lambda_forecasts.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_forecasts_dynamodb" {
  name = "${local.name_prefix}-lambda-forecasts-dynamodb"
  role = aws_iam_role.lambda_forecasts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_forecasts_xray" {
  name = "${local.name_prefix}-lambda-forecasts-xray"
  role = aws_iam_role.lambda_forecasts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Textract Processor Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_textract" {
  name               = "${local.name_prefix}-lambda-textract-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_textract_basic" {
  role       = aws_iam_role.lambda_textract.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_textract_dynamodb" {
  name = "${local.name_prefix}-lambda-textract-dynamodb"
  role = aws_iam_role.lambda_textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_textract_s3" {
  name = "${local.name_prefix}-lambda-textract-s3"
  role = aws_iam_role.lambda_textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_textract_textract" {
  name = "${local.name_prefix}-lambda-textract-textract"
  role = aws_iam_role.lambda_textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "textract:DetectDocumentText",
          "textract:AnalyzeDocument"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_textract_xray" {
  name = "${local.name_prefix}-lambda-textract-xray"
  role = aws_iam_role.lambda_textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Reminder Scheduler Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_reminder" {
  name               = "${local.name_prefix}-lambda-reminder-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_reminder_basic" {
  role       = aws_iam_role.lambda_reminder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_reminder_dynamodb" {
  name = "${local.name_prefix}-lambda-reminder-dynamodb"
  role = aws_iam_role.lambda_reminder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_reminder_sns" {
  name = "${local.name_prefix}-lambda-reminder-sns"
  role = aws_iam_role.lambda_reminder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cheque_reminders.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_reminder_xray" {
  name = "${local.name_prefix}-lambda-reminder-xray"
  role = aws_iam_role.lambda_reminder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# ML Forecast Lambda IAM Role
# ============================================================================

resource "aws_iam_role" "lambda_ml_forecast" {
  name               = "${local.name_prefix}-lambda-ml-forecast-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_ml_forecast_basic" {
  role       = aws_iam_role.lambda_ml_forecast.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ml_forecast_dynamodb" {
  name = "${local.name_prefix}-lambda-ml-forecast-dynamodb"
  role = aws_iam_role.lambda_ml_forecast.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ml_forecast_sagemaker" {
  name = "${local.name_prefix}-lambda-ml-forecast-sagemaker"
  role = aws_iam_role.lambda_ml_forecast.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpoint",
          "sagemaker:CreateTransformJob",
          "sagemaker:DescribeTransformJob"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ml_forecast_xray" {
  name = "${local.name_prefix}-lambda-ml-forecast-xray"
  role = aws_iam_role.lambda_ml_forecast.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# API Gateway CloudWatch Logging Role
# ============================================================================

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# ============================================================================
# SES Email Sending Policy (for Lambda if needed)
# ============================================================================

resource "aws_iam_policy" "ses_send_email" {
  name        = "${local.name_prefix}-ses-send-email-policy"
  description = "Allow sending emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach to reminder Lambda if needed for direct SES sending
# resource "aws_iam_role_policy_attachment" "lambda_reminder_ses" {
#   role       = aws_iam_role.lambda_reminder.name
#   policy_arn = aws_iam_policy.ses_send_email.arn
# }

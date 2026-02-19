# ============================================================================
# Lambda Functions
# ============================================================================
# Purpose: Serverless compute for business logic
# Best Practice: Separate functions per domain, least privilege IAM
# ============================================================================

# ============================================================================
# Lambda Layer for Shared Dependencies
# ============================================================================
# Purpose: Share common dependencies across Lambda functions
# Best Practice: Reduces deployment package size, faster deployments
# ============================================================================

resource "aws_lambda_layer_version" "dependencies" {
  filename            = "${path.module}/../lambda/layers/dependencies.zip"
  layer_name          = "${var.project_name}-dependencies-${var.environment}"
  compatible_runtimes = ["nodejs18.x"]
  description         = "Shared dependencies for Lambda functions"

  # Only create if the zip file exists
  lifecycle {
    ignore_changes = [filename]
  }
}

# ============================================================================
# Cheque Management Lambda
# ============================================================================

resource "aws_lambda_function" "cheques" {
  filename         = "${path.module}/../lambda/functions/cheques.zip"
  function_name    = "${var.project_name}-cheques-${var.environment}"
  role             = aws_iam_role.lambda_cheques.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/cheques.zip") ? filebase64sha256("${path.module}/../lambda/functions/cheques.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME            = aws_dynamodb_table.main.name
      S3_BUCKET_NAME        = aws_s3_bucket.cheque_images.id
      PRESIGNED_URL_EXPIRY  = "900"
      ENVIRONMENT           = var.environment
      LOG_LEVEL             = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active" # Enable X-Ray tracing
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cheques-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# CloudWatch Log Group for Cheques Lambda
resource "aws_cloudwatch_log_group" "cheques" {
  name              = "/aws/lambda/${aws_lambda_function.cheques.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Supplier Management Lambda
# ============================================================================

resource "aws_lambda_function" "suppliers" {
  filename         = "${path.module}/../lambda/functions/suppliers.zip"
  function_name    = "${var.project_name}-suppliers-${var.environment}"
  role             = aws_iam_role.lambda_suppliers.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/suppliers.zip") ? filebase64sha256("${path.module}/../lambda/functions/suppliers.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-suppliers-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "suppliers" {
  name              = "/aws/lambda/${aws_lambda_function.suppliers.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Bank Account Management Lambda
# ============================================================================

resource "aws_lambda_function" "bank_accounts" {
  filename         = "${path.module}/../lambda/functions/bank-accounts.zip"
  function_name    = "${var.project_name}-bank-accounts-${var.environment}"
  role             = aws_iam_role.lambda_bank_accounts.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/bank-accounts.zip") ? filebase64sha256("${path.module}/../lambda/functions/bank-accounts.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bank-accounts-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "bank_accounts" {
  name              = "/aws/lambda/${aws_lambda_function.bank_accounts.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Notification Management Lambda
# ============================================================================

resource "aws_lambda_function" "notifications" {
  filename         = "${path.module}/../lambda/functions/notifications.zip"
  function_name    = "${var.project_name}-notifications-${var.environment}"
  role             = aws_iam_role.lambda_notifications.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/notifications.zip") ? filebase64sha256("${path.module}/../lambda/functions/notifications.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-notifications-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "notifications" {
  name              = "/aws/lambda/${aws_lambda_function.notifications.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Report Generation Lambda
# ============================================================================

resource "aws_lambda_function" "reports" {
  filename         = "${path.module}/../lambda/functions/reports.zip"
  function_name    = "${var.project_name}-reports-${var.environment}"
  role             = aws_iam_role.lambda_reports.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/reports.zip") ? filebase64sha256("${path.module}/../lambda/functions/reports.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 60 # Longer timeout for report generation
  memory_size      = 1024

  environment {
    variables = {
      TABLE_NAME           = aws_dynamodb_table.main.name
      S3_BUCKET_NAME       = aws_s3_bucket.cheque_images.id
      PRESIGNED_URL_EXPIRY = "3600"
      ENVIRONMENT          = var.environment
      LOG_LEVEL            = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-reports-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "reports" {
  name              = "/aws/lambda/${aws_lambda_function.reports.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Forecast Management Lambda
# ============================================================================

resource "aws_lambda_function" "forecasts" {
  filename         = "${path.module}/../lambda/functions/forecasts.zip"
  function_name    = "${var.project_name}-forecasts-${var.environment}"
  role             = aws_iam_role.lambda_forecasts.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/forecasts.zip") ? filebase64sha256("${path.module}/../lambda/functions/forecasts.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-forecasts-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "forecasts" {
  name              = "/aws/lambda/${aws_lambda_function.forecasts.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# Textract OCR Processor Lambda
# ============================================================================

resource "aws_lambda_function" "textract_processor" {
  filename         = "${path.module}/../lambda/functions/textract-processor.zip"
  function_name    = "${var.project_name}-textract-processor-${var.environment}"
  role             = aws_iam_role.lambda_textract.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/textract-processor.zip") ? filebase64sha256("${path.module}/../lambda/functions/textract-processor.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 60 # Textract can take time
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-textract-processor-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "textract_processor" {
  name              = "/aws/lambda/${aws_lambda_function.textract_processor.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# S3 trigger for Textract Lambda
resource "aws_lambda_permission" "allow_s3_textract" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.textract_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cheque_images.arn
}

# ============================================================================
# Reminder Scheduler Lambda
# ============================================================================

resource "aws_lambda_function" "reminder_scheduler" {
  filename         = "${path.module}/../lambda/functions/reminder-scheduler.zip"
  function_name    = "${var.project_name}-reminder-scheduler-${var.environment}"
  role             = aws_iam_role.lambda_reminder.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/reminder-scheduler.zip") ? filebase64sha256("${path.module}/../lambda/functions/reminder-scheduler.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 300 # 5 minutes for batch processing
  memory_size      = 512

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.main.name
      SNS_TOPIC_ARN = aws_sns_topic.cheque_reminders.arn
      ENVIRONMENT   = var.environment
      LOG_LEVEL     = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-reminder-scheduler-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "reminder_scheduler" {
  name              = "/aws/lambda/${aws_lambda_function.reminder_scheduler.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# EventBridge permission for Reminder Lambda
resource "aws_lambda_permission" "allow_eventbridge_reminder" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reminder_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_reminder.arn
}

# ============================================================================
# ML Forecast Lambda
# ============================================================================

resource "aws_lambda_function" "ml_forecast" {
  filename         = "${path.module}/../lambda/functions/ml-forecast.zip"
  function_name    = "${var.project_name}-ml-forecast-${var.environment}"
  role             = aws_iam_role.lambda_ml_forecast.arn
  handler          = "index.handler"
  source_code_hash = fileexists("${path.module}/../lambda/functions/ml-forecast.zip") ? filebase64sha256("${path.module}/../lambda/functions/ml-forecast.zip") : null
  runtime          = "nodejs18.x"
  timeout          = 300 # 5 minutes for ML processing
  memory_size      = 1024

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.main.name
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ml-forecast-${var.environment}"
    }
  )

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "ml_forecast" {
  name              = "/aws/lambda/${aws_lambda_function.ml_forecast.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# EventBridge permission for ML Forecast Lambda
resource "aws_lambda_permission" "allow_eventbridge_ml" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ml_forecast.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_ml_forecast.arn
}

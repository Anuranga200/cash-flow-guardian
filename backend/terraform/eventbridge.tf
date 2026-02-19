# ============================================================================
# EventBridge Rules for Scheduled Tasks
# ============================================================================
# Purpose: Trigger Lambda functions on schedule (cron)
# Best Practice: Use EventBridge over CloudWatch Events (modern service)
# ============================================================================

# ============================================================================
# Daily Reminder Rule
# ============================================================================
# Purpose: Check for upcoming cheques daily at 9 AM UTC
# Schedule: Every day at 9:00 AM UTC
# ============================================================================

resource "aws_cloudwatch_event_rule" "daily_reminder" {
  name                = "${var.project_name}-daily-reminder-${var.environment}"
  description         = "Trigger daily cheque reminder check"
  schedule_expression = "cron(0 9 * * ? *)" # 9 AM UTC daily

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-daily-reminder-${var.environment}"
    }
  )
}

resource "aws_cloudwatch_event_target" "daily_reminder" {
  rule      = aws_cloudwatch_event_rule.daily_reminder.name
  target_id = "ReminderLambda"
  arn       = aws_lambda_function.reminder_scheduler.arn

  # Retry policy for failed invocations
  retry_policy {
    maximum_event_age       = 3600 # 1 hour
    maximum_retry_attempts  = 2
  }

  # Dead letter queue for failed events
  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_dlq.arn
  }
}

# ============================================================================
# Weekly ML Forecast Rule
# ============================================================================
# Purpose: Generate ML forecasts weekly on Sunday at 2 AM UTC
# Schedule: Every Sunday at 2:00 AM UTC
# ============================================================================

resource "aws_cloudwatch_event_rule" "weekly_ml_forecast" {
  name                = "${var.project_name}-weekly-ml-forecast-${var.environment}"
  description         = "Trigger weekly ML forecast generation"
  schedule_expression = "cron(0 2 ? * SUN *)" # 2 AM UTC every Sunday

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-weekly-ml-forecast-${var.environment}"
    }
  )
}

resource "aws_cloudwatch_event_target" "weekly_ml_forecast" {
  rule      = aws_cloudwatch_event_rule.weekly_ml_forecast.name
  target_id = "MLForecastLambda"
  arn       = aws_lambda_function.ml_forecast.arn

  retry_policy {
    maximum_event_age       = 7200 # 2 hours
    maximum_retry_attempts  = 2
  }

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_dlq.arn
  }
}

# ============================================================================
# Dead Letter Queue for Failed EventBridge Events
# ============================================================================
# Purpose: Capture failed events for debugging and replay
# Best Practice: Always use DLQ for production event-driven systems
# ============================================================================

resource "aws_sqs_queue" "eventbridge_dlq" {
  name                      = "${var.project_name}-eventbridge-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eventbridge-dlq-${var.environment}"
    }
  )
}

resource "aws_sqs_queue_policy" "eventbridge_dlq" {
  queue_url = aws_sqs_queue.eventbridge_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.eventbridge_dlq.arn
      }
    ]
  })
}

# ============================================================================
# CloudWatch Alarm for DLQ Messages
# ============================================================================
# Purpose: Alert when events fail and land in DLQ
# Best Practice: Monitor DLQ depth to catch systematic failures
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "eventbridge_dlq_alarm" {
  alarm_name          = "${var.project_name}-eventbridge-dlq-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when EventBridge events fail and land in DLQ"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.eventbridge_dlq.name
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

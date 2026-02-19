# ============================================================================
# SNS Topic for Cheque Reminders
# ============================================================================
# Purpose: Pub/Sub messaging for email notifications
# Best Practice: Decouple Lambda from SES, enable fan-out pattern
# ============================================================================

resource "aws_sns_topic" "cheque_reminders" {
  name              = "${var.project_name}-cheque-reminders-${var.environment}"
  display_name      = "Cheque Payment Reminders"
  delivery_policy   = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cheque-reminders-${var.environment}"
    }
  )
}

# ============================================================================
# SNS Topic Policy
# ============================================================================
# Purpose: Allow Lambda to publish messages
# ============================================================================

resource "aws_sns_topic_policy" "cheque_reminders" {
  arn = aws_sns_topic.cheque_reminders.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cheque_reminders.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_lambda_function.reminder_scheduler.arn
          }
        }
      }
    ]
  })
}

# ============================================================================
# SNS Email Subscription (Manual - requires confirmation)
# ============================================================================
# Purpose: Subscribe email addresses to receive notifications
# Note: Email subscriptions require manual confirmation
# Best Practice: Use SES for programmatic email sending
# ============================================================================

# Uncomment and add email addresses after deployment
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.cheque_reminders.arn
#   protocol  = "email"
#   endpoint  = var.notification_email
# }

# ============================================================================
# SES Email Identity (Domain or Email)
# ============================================================================
# Purpose: Verify sender email/domain for SES
# Note: Requires manual verification in AWS Console
# Best Practice: Use domain identity for production
# ============================================================================

# Email identity (for sandbox/testing)
resource "aws_ses_email_identity" "sender" {
  count = var.ses_sender_email != "" ? 1 : 0
  email = var.ses_sender_email
}

# Domain identity (for production)
# resource "aws_ses_domain_identity" "main" {
#   domain = var.ses_domain
# }

# ============================================================================
# SES Configuration Set
# ============================================================================
# Purpose: Track email sending metrics and events
# Best Practice: Monitor bounce/complaint rates
# ============================================================================

resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}"

  delivery_options {
    tls_policy = "Require" # Enforce TLS for email delivery
  }

  reputation_metrics_enabled = true
}

# ============================================================================
# SES Event Destination (CloudWatch)
# ============================================================================
# Purpose: Send SES events to CloudWatch for monitoring
# ============================================================================

resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}

# ============================================================================
# SNS Topics for SES Bounce and Complaint Handling
# ============================================================================
# Purpose: Handle email bounces and complaints
# Best Practice: Monitor and act on bounce/complaint notifications
# ============================================================================

resource "aws_sns_topic" "ses_bounces" {
  name = "${var.project_name}-ses-bounces-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ses-bounces-${var.environment}"
    }
  )
}

resource "aws_sns_topic" "ses_complaints" {
  name = "${var.project_name}-ses-complaints-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ses-complaints-${var.environment}"
    }
  )
}

# ============================================================================
# SES Identity Notification Topic (Bounces)
# ============================================================================

resource "aws_ses_identity_notification_topic" "bounces" {
  count                    = var.ses_sender_email != "" ? 1 : 0
  topic_arn                = aws_sns_topic.ses_bounces.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_email_identity.sender[0].email
  include_original_headers = true
}

# ============================================================================
# SES Identity Notification Topic (Complaints)
# ============================================================================

resource "aws_ses_identity_notification_topic" "complaints" {
  count                    = var.ses_sender_email != "" ? 1 : 0
  topic_arn                = aws_sns_topic.ses_complaints.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_email_identity.sender[0].email
  include_original_headers = true
}

# ============================================================================
# CloudWatch Alarms for SES Metrics
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate" {
  alarm_name          = "${var.project_name}-ses-bounce-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = "3600" # 1 hour
  statistic           = "Average"
  threshold           = "0.05" # 5% bounce rate
  alarm_description   = "Alert when SES bounce rate exceeds 5%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate" {
  alarm_name          = "${var.project_name}-ses-complaint-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = "3600" # 1 hour
  statistic           = "Average"
  threshold           = "0.001" # 0.1% complaint rate
  alarm_description   = "Alert when SES complaint rate exceeds 0.1%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.common_tags
}

# ============================================================================
# Lambda Permission for SNS to invoke SES (if using Lambda for email)
# ============================================================================
# Note: This is optional if you want SNS to trigger a Lambda that sends via SES
# For direct SES sending from Lambda, this is not needed
# ============================================================================

# resource "aws_lambda_permission" "allow_sns_ses" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.ses_sender.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.cheque_reminders.arn
# }

# ============================================================================
# Amazon DynamoDB - Single Table Design
# ============================================================================
# Best Practices:
# - Single table design for cost efficiency
# - On-demand billing for unpredictable workloads
# - Encryption at rest with AWS managed keys
# - Point-in-time recovery for data protection
# - Stream disabled initially (enable for audit trail if needed)
# ============================================================================

resource "aws_dynamodb_table" "main" {
  name           = "${local.name_prefix}-finance-table"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "PK"
  range_key      = "SK"

  # ============================================================================
  # Primary Key Schema - Requirement 12.1
  # ============================================================================
  attribute {
    name = "PK"
    type = "S" # String - Partition Key
  }

  attribute {
    name = "SK"
    type = "S" # String - Sort Key
  }

  # ============================================================================
  # Global Secondary Index 1 - Cheque Status Index (Optional)
  # ============================================================================
  # Uncomment if query performance requires status-based queries
  # attribute {
  #   name = "GSI1PK"
  #   type = "S"
  # }
  #
  # attribute {
  #   name = "GSI1SK"
  #   type = "S"
  # }
  #
  # global_secondary_index {
  #   name            = "GSI1"
  #   hash_key        = "GSI1PK"
  #   range_key       = "GSI1SK"
  #   projection_type = "ALL"
  # }

  # ============================================================================
  # Global Secondary Index 2 - Cheque Date Index (Optional)
  # ============================================================================
  # Uncomment for efficient date-based queries (reminder system)
  # attribute {
  #   name = "GSI2PK"
  #   type = "S"
  # }
  #
  # attribute {
  #   name = "GSI2SK"
  #   type = "S"
  # }
  #
  # global_secondary_index {
  #   name            = "GSI2"
  #   hash_key        = "GSI2PK"
  #   range_key       = "GSI2SK"
  #   projection_type = "ALL"
  # }

  # ============================================================================
  # Time to Live (TTL) - Optional
  # ============================================================================
  # Uncomment to enable automatic deletion of expired items
  # ttl {
  #   attribute_name = "ttl"
  #   enabled        = true
  # }

  # ============================================================================
  # Encryption - Requirement 12.3
  # ============================================================================
  server_side_encryption {
    enabled     = true
    kms_key_arn = null # Use AWS managed key (free)
    # For customer managed key:
    # kms_key_arn = aws_kms_key.dynamodb.arn
  }

  # ============================================================================
  # Point-in-Time Recovery - Requirement 12.4
  # ============================================================================
  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  # ============================================================================
  # DynamoDB Streams (Optional)
  # ============================================================================
  # Enable for audit trail or event-driven architectures
  # stream_enabled   = true
  # stream_view_type = "NEW_AND_OLD_IMAGES"

  # ============================================================================
  # Deletion Protection
  # ============================================================================
  deletion_protection_enabled = var.environment == "prod" ? true : false

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-finance-table"
    }
  )
}

# ============================================================================
# DynamoDB Table Autoscaling (Optional - for Provisioned Mode)
# ============================================================================
# Uncomment if using PROVISIONED billing mode

# resource "aws_appautoscaling_target" "dynamodb_table_read" {
#   count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
#   max_capacity       = 100
#   min_capacity       = 5
#   resource_id        = "table/${aws_dynamodb_table.main.name}"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }
#
# resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
#   count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
#   name               = "${local.name_prefix}-dynamodb-read-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.dynamodb_table_read[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.dynamodb_table_read[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.dynamodb_table_read[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = 70.0
#   }
# }
#
# resource "aws_appautoscaling_target" "dynamodb_table_write" {
#   count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
#   max_capacity       = 100
#   min_capacity       = 5
#   resource_id        = "table/${aws_dynamodb_table.main.name}"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   service_namespace  = "dynamodb"
# }
#
# resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
#   count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
#   name               = "${local.name_prefix}-dynamodb-write-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.dynamodb_table_write[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.dynamodb_table_write[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.dynamodb_table_write[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = 70.0
#   }
# }

# ============================================================================
# CloudWatch Alarms for DynamoDB
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${local.name_prefix}-dynamodb-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "DynamoDB read throttle events exceeded threshold"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${local.name_prefix}-dynamodb-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "DynamoDB write throttle events exceeded threshold"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    TableName = aws_dynamodb_table.main.name
  }

  tags = local.common_tags
}

# ============================================================================
# Amazon S3 - Cheque Images and Reports Storage
# ============================================================================
# Best Practices:
# - Block all public access
# - Server-side encryption (SSE-S3)
# - Versioning disabled (cost optimization)
# - Lifecycle policy for cost optimization
# - CORS configuration for pre-signed URL uploads
# - Event notifications for Textract processing
# ============================================================================

# ============================================================================
# S3 Bucket
# ============================================================================

resource "aws_s3_bucket" "main" {
  bucket = "${local.name_prefix}-storage-${data.aws_caller_identity.current.account_id}"

  # Force destroy for non-prod environments (careful in production!)
  force_destroy = var.environment != "prod"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-storage"
    }
  )
}

# ============================================================================
# Block Public Access - Requirement 13.1
# ============================================================================

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# Server-Side Encryption - Requirement 13.2
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3 (free)
      # For KMS encryption:
      # sse_algorithm     = "aws:kms"
      # kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true # Reduces KMS costs if using KMS
  }
}

# ============================================================================
# Versioning (Disabled for Cost Optimization)
# ============================================================================

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Disabled"
    # Enable for production if version history is required:
    # status = "Enabled"
  }
}

# ============================================================================
# Lifecycle Policy - Cost Optimization
# ============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Transition cheque images to Glacier after 1 year
  rule {
    id     = "archive-cheque-images"
    status = "Enabled"

    filter {
      prefix = "*/cheques/"
    }

    transition {
      days          = var.s3_lifecycle_glacier_days
      storage_class = "GLACIER"
    }

    # Optional: Delete after retention period
    dynamic "expiration" {
      for_each = var.s3_lifecycle_expiration_days > 0 ? [1] : []
      content {
        days = var.s3_lifecycle_expiration_days
      }
    }
  }

  # Delete temporary reports after 7 days
  rule {
    id     = "cleanup-reports"
    status = "Enabled"

    filter {
      prefix = "*/reports/"
    }

    expiration {
      days = 7
    }
  }

  # Cleanup incomplete multipart uploads
  rule {
    id     = "cleanup-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ============================================================================
# CORS Configuration - For Pre-Signed URL Uploads
# ============================================================================

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "x-amz-server-side-encryption"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# S3 Event Notification - Trigger Textract Lambda
# ============================================================================

resource "aws_s3_bucket_notification" "textract_trigger" {
  bucket = aws_s3_bucket.main.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.textract_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
    
    # Only trigger for cheque images
    filter_prefix = ""
    filter_suffix = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3_textract]
}

# ============================================================================
# Lambda Permission for S3 to Invoke Textract Function
# ============================================================================

resource "aws_lambda_permission" "allow_s3_textract" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.textract_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# ============================================================================
# S3 Bucket Policy - Enforce SSL/TLS
# ============================================================================

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ============================================================================
# CloudWatch Alarms for S3
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "${local.name_prefix}-s3-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "S3 4xx errors exceeded threshold (permission issues)"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    BucketName = aws_s3_bucket.main.id
    FilterId   = "EntireBucket"
  }

  tags = local.common_tags
}

# ============================================================================
# Data Source - Current AWS Account
# ============================================================================

data "aws_caller_identity" "current" {}

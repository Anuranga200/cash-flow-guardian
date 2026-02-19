# ============================================================================
# Amazon Cognito User Pool - Authentication & Authorization
# ============================================================================
# Best Practices:
# - Strong password policy with complexity requirements
# - Email verification for account security
# - Optional MFA for enhanced security
# - Account recovery via email
# - User pool domain for hosted UI (optional)
# ============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-user-pool"

  # ============================================================================
  # Password Policy - Requirement 1.6
  # ============================================================================
  password_policy {
    minimum_length                   = var.cognito_password_minimum_length
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # ============================================================================
  # MFA Configuration - Requirement 1.7
  # ============================================================================
  mfa_configuration = var.cognito_mfa_configuration

  # Enable software token MFA (TOTP)
  software_token_mfa_configuration {
    enabled = true
  }

  # ============================================================================
  # Email Configuration - Requirement 1.1
  # ============================================================================
  auto_verified_attributes = ["email"]
  
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
    # For production, use SES:
    # email_sending_account = "DEVELOPER"
    # source_arn           = aws_ses_email_identity.cognito.arn
  }

  # ============================================================================
  # User Attributes Schema
  # ============================================================================
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # ============================================================================
  # Account Recovery
  # ============================================================================
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # ============================================================================
  # User Pool Add-ons
  # ============================================================================
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED" # Protects against compromised credentials
  }

  # ============================================================================
  # Username Configuration
  # ============================================================================
  username_attributes      = ["email"]
  username_configuration {
    case_sensitive = false
  }

  # ============================================================================
  # Admin Create User Configuration
  # ============================================================================
  admin_create_user_config {
    allow_admin_create_user_only = false # Allow self-registration
  }

  # ============================================================================
  # Device Tracking (Optional)
  # ============================================================================
  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = true
  }

  # ============================================================================
  # Deletion Protection
  # ============================================================================
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-user-pool"
    }
  )
}

# ============================================================================
# Cognito User Pool Client - Web Application
# ============================================================================

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "${local.name_prefix}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # ============================================================================
  # OAuth Configuration
  # ============================================================================
  generate_secret = false # Public client (SPA)

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",           # Secure Remote Password
    "ALLOW_REFRESH_TOKEN_AUTH",      # Refresh tokens
    "ALLOW_USER_PASSWORD_AUTH"       # Username/password (for testing)
  ]

  # ============================================================================
  # Token Configuration
  # ============================================================================
  refresh_token_validity = 30 # days
  access_token_validity  = 60 # minutes
  id_token_validity      = 60 # minutes

  token_validity_units {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  # ============================================================================
  # Prevent User Existence Errors
  # ============================================================================
  prevent_user_existence_errors = "ENABLED"

  # ============================================================================
  # Read/Write Attributes
  # ============================================================================
  read_attributes = [
    "email",
    "email_verified",
    "name"
  ]

  write_attributes = [
    "email",
    "name"
  ]
}

# ============================================================================
# Cognito User Pool Domain (Optional - for Hosted UI)
# ============================================================================

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.name_prefix}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ============================================================================
# Cognito Identity Pool (Optional - for AWS SDK access)
# ============================================================================
# Uncomment if you need direct AWS service access from frontend

# resource "aws_cognito_identity_pool" "main" {
#   identity_pool_name               = "${local.name_prefix}-identity-pool"
#   allow_unauthenticated_identities = false
#
#   cognito_identity_providers {
#     client_id               = aws_cognito_user_pool_client.web_client.id
#     provider_name           = aws_cognito_user_pool.main.endpoint
#     server_side_token_check = false
#   }
# }

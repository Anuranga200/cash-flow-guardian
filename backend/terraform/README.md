# Cheque Management System - Terraform Infrastructure

## 📋 Overview

This Terraform configuration deploys a complete serverless backend infrastructure for the Cheque Management System on AWS. The architecture follows AWS Well-Architected Framework principles with emphasis on:

- **Serverless-First**: Minimize operational overhead
- **Cost Optimization**: Pay-per-use pricing model
- **Security**: Encryption, least privilege IAM, private resources
- **Observability**: Comprehensive logging and monitoring
- **Scalability**: Auto-scaling serverless components

## 🏗️ Architecture Components

### Core Services
- **Amazon Cognito**: User authentication and JWT token management
- **API Gateway**: REST API with JWT authorizer
- **AWS Lambda**: 9 serverless functions for business logic
- **DynamoDB**: Single-table design for all data storage
- **S3**: Encrypted storage for cheque images and reports
- **Amazon Textract**: OCR for cheque image processing
- **EventBridge**: Scheduled triggers for reminders and ML forecasts
- **SNS + SES**: Email notification delivery
- **CloudWatch**: Logging, metrics, and alarms
- **X-Ray**: Distributed tracing

### Lambda Functions
1. **Cheques Lambda**: CRUD operations for cheques
2. **Suppliers Lambda**: Supplier management
3. **Bank Accounts Lambda**: Bank account and transaction management
4. **Notifications Lambda**: In-app notification management
5. **Reports Lambda**: Excel report generation
6. **Forecasts Lambda**: ML forecast retrieval
7. **Textract Processor**: OCR processing for uploaded images
8. **Reminder Scheduler**: Daily cheque reminder job
9. **ML Forecast**: Weekly cash flow forecasting

## 📁 File Structure

```
backend/terraform/
├── main.tf                 # Provider and backend configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── cognito.tf              # Cognito User Pool and App Client
├── dynamodb.tf             # DynamoDB single table
├── s3.tf                   # S3 buckets for images and reports
├── iam.tf                  # IAM roles and policies
├── lambda.tf               # Lambda functions and layers
├── api_gateway.tf          # API Gateway REST API
├── eventbridge.tf          # EventBridge rules for scheduling
├── sns_ses.tf              # SNS topics and SES configuration
├── cloudwatch.tf           # CloudWatch alarms and dashboard
├── modules/
│   └── cors/
│       └── main.tf         # Reusable CORS module
└── README.md               # This file
```

## 🚀 Prerequisites

### Required Tools
- **Terraform**: v1.5.0 or later
- **AWS CLI**: v2.x configured with credentials
- **Node.js**: v18.x (for Lambda function packaging)
- **AWS Account**: With appropriate permissions

### AWS Permissions Required
The IAM user/role running Terraform needs permissions for:
- Cognito (User Pools)
- API Gateway
- Lambda
- DynamoDB
- S3
- IAM (role creation)
- CloudWatch (logs, alarms, dashboards)
- EventBridge
- SNS
- SES
- Textract
- X-Ray

## 📝 Configuration

### 1. Create `terraform.tfvars`

Create a `terraform.tfvars` file with your environment-specific values:

```hcl
# Environment Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "cheque-management"

# Cognito Configuration
cognito_password_minimum_length = 8
cognito_mfa_configuration       = "OPTIONAL"

# SES Configuration (IMPORTANT: Must verify email in AWS Console)
ses_sender_email   = "noreply@yourdomain.com"
notification_email = "admin@yourdomain.com"

# CORS Configuration (Update with your frontend URL)
cors_allowed_origins = [
  "http://localhost:5173",
  "http://localhost:3000",
  "https://your-frontend-domain.com"
]

# CloudWatch Configuration
log_retention_days = 30
enable_xray_tracing = true

# API Gateway Configuration
api_throttle_burst_limit = 5000
api_throttle_rate_limit  = 2000
api_quota_limit          = 100000

# DynamoDB Configuration
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_point_in_time_recovery = true

# S3 Configuration
s3_lifecycle_glacier_days    = 365
s3_lifecycle_expiration_days = 0

# EventBridge Configuration
reminder_schedule_expression    = "cron(0 9 * * ? *)"    # 9 AM UTC daily
ml_forecast_schedule_expression = "cron(0 2 ? * SUN *)"  # 2 AM UTC Sunday

# Tags
common_tags = {
  Project     = "Cheque Management System"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CostCenter  = "Finance"
  Owner       = "admin@yourdomain.com"
}
```

### 2. Backend Configuration (Optional but Recommended)

For production, configure remote state storage in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "cheque-management/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## 🔧 Deployment Steps

### Step 1: Initialize Terraform

```bash
cd backend/terraform
terraform init
```

This downloads required providers and initializes the backend.

### Step 2: Validate Configuration

```bash
terraform validate
```

Checks for syntax errors and configuration issues.

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the execution plan carefully. This shows what resources will be created.

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

Creates all AWS resources. This takes 5-10 minutes.

### Step 5: Save Outputs

```bash
terraform output -json > outputs.json
```

Save outputs for frontend configuration.

## 📦 Lambda Function Deployment

### Important Note
The Terraform configuration expects Lambda function ZIP files to exist at:
```
backend/lambda/functions/cheques.zip
backend/lambda/functions/suppliers.zip
backend/lambda/functions/bank-accounts.zip
backend/lambda/functions/notifications.zip
backend/lambda/functions/reports.zip
backend/lambda/functions/forecasts.zip
backend/lambda/functions/textract-processor.zip
backend/lambda/functions/reminder-scheduler.zip
backend/lambda/functions/ml-forecast.zip
```

### Creating Placeholder ZIPs (for initial deployment)

```bash
# Create lambda functions directory
mkdir -p ../lambda/functions

# Create placeholder Lambda functions
for func in cheques suppliers bank-accounts notifications reports forecasts textract-processor reminder-scheduler ml-forecast; do
  echo 'exports.handler = async (event) => { return { statusCode: 200, body: JSON.stringify({ message: "Placeholder" }) }; };' > ../lambda/functions/index.js
  cd ../lambda/functions
  zip ${func}.zip index.js
  rm index.js
  cd ../../terraform
done
```

### Deploying Real Lambda Code

After initial infrastructure deployment, replace placeholder ZIPs with actual Lambda code and update:

```bash
terraform apply -target=aws_lambda_function.cheques
terraform apply -target=aws_lambda_function.suppliers
# ... repeat for each function
```

## 🔐 Post-Deployment Configuration

### 1. Verify SES Email Address

**CRITICAL**: SES starts in sandbox mode. You must verify sender email:

```bash
# Via AWS CLI
aws ses verify-email-identity --email-address noreply@yourdomain.com

# Or via AWS Console:
# 1. Go to SES Console
# 2. Click "Email Addresses" under "Identity Management"
# 3. Click "Verify a New Email Address"
# 4. Enter your email and click "Verify This Email Address"
# 5. Check your inbox and click the verification link
```

### 2. Request SES Production Access

For production email sending:

1. Go to SES Console
2. Click "Sending Statistics"
3. Click "Request Production Access"
4. Fill out the form (typically approved in 24-48 hours)

### 3. Create Cognito User

```bash
# Get User Pool ID from outputs
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)

# Create a test user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@example.com \
  --user-attributes Name=email,Value=admin@example.com Name=email_verified,Value=true \
  --temporary-password TempPassword123! \
  --message-action SUPPRESS

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username admin@example.com \
  --password YourSecurePassword123! \
  --permanent
```

### 4. Configure Frontend

Use the `environment_config` output to configure your frontend:

```bash
terraform output -json environment_config
```

Update your frontend `.env` file:

```env
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_API_ENDPOINT=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev
VITE_S3_BUCKET=cheque-management-images-dev-xxxxxxxxxxxx
```

## 📊 Monitoring and Observability

### CloudWatch Dashboard

Access the dashboard:
```bash
DASHBOARD_NAME=$(terraform output -raw cloudwatch_dashboard_name)
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=$DASHBOARD_NAME"
```

### View Lambda Logs

```bash
# Cheques Lambda logs
aws logs tail /aws/lambda/cheque-management-cheques-dev --follow

# All Lambda logs
aws logs tail --follow --filter-pattern "ERROR"
```

### CloudWatch Alarms

Alarms are configured for:
- Lambda errors (> 5 in 5 minutes)
- Lambda throttles
- API Gateway 5xx errors (> 10 in 5 minutes)
- API Gateway 4xx errors (> 100 in 10 minutes)
- API Gateway latency (> 2 seconds)
- DynamoDB throttles
- SES bounce rate (> 5%)
- SES complaint rate (> 0.1%)
- EventBridge DLQ messages

### X-Ray Tracing

View distributed traces:
```bash
echo "https://console.aws.amazon.com/xray/home?region=us-east-1#/service-map"
```

## 💰 Cost Estimation

### Monthly Cost Breakdown (Low Traffic - ~1000 requests/day)

| Service | Usage | Cost |
|---------|-------|------|
| API Gateway | 30K requests | $0.03 |
| Lambda | 30K invocations, 512MB, 1s avg | $0.60 |
| DynamoDB | 30K reads, 10K writes | $0.38 |
| S3 | 10GB storage, 1K uploads | $0.25 |
| Cognito | 50 MAU | $0.28 |
| CloudWatch | Logs + Metrics | $5.00 |
| SES | 1K emails | $0.10 |
| Textract | 100 pages | $1.50 |
| **Total** | | **~$8.14/month** |

### Cost Optimization Tips

1. **Use On-Demand Billing**: Start with PAY_PER_REQUEST for DynamoDB
2. **Adjust Log Retention**: Reduce to 7 days for dev environments
3. **Disable X-Ray in Dev**: Set `enable_xray_tracing = false`
4. **S3 Lifecycle Policies**: Move old images to Glacier
5. **Lambda Memory**: Right-size based on actual usage
6. **API Gateway Caching**: Enable for frequently accessed endpoints

## 🔒 Security Best Practices

### Implemented Security Measures

✅ **Encryption at Rest**
- DynamoDB: AWS managed keys
- S3: SSE-S3 encryption
- CloudWatch Logs: Encrypted

✅ **Encryption in Transit**
- API Gateway: HTTPS only
- SES: TLS required

✅ **IAM Least Privilege**
- Each Lambda has minimal required permissions
- No wildcard (*) permissions

✅ **Network Security**
- S3: Block all public access
- API Gateway: JWT authorizer required

✅ **Data Isolation**
- Multi-tenant data isolation via userId in partition key

✅ **Audit Trail**
- CloudWatch Logs for all API calls
- X-Ray tracing for request flow
- Transaction records for balance changes

### Additional Security Recommendations

1. **Enable MFA**: Set `cognito_mfa_configuration = "ON"` for production
2. **Restrict CORS**: Update `cors_allowed_origins` with actual frontend domain
3. **Enable WAF**: Add AWS WAF to API Gateway for production
4. **Rotate Secrets**: Use AWS Secrets Manager for sensitive config
5. **Enable GuardDuty**: For threat detection
6. **Regular Audits**: Use AWS Config for compliance

## 🧪 Testing

### Test API Gateway Endpoint

```bash
API_URL=$(terraform output -raw api_gateway_invoke_url)

# Health check (if implemented)
curl $API_URL/health

# Test with authentication
# 1. Get JWT token from Cognito
# 2. Make authenticated request
curl -H "Authorization: Bearer $JWT_TOKEN" $API_URL/v1/cheques
```

### Test Lambda Functions Directly

```bash
# Invoke Cheques Lambda
aws lambda invoke \
  --function-name cheque-management-cheques-dev \
  --payload '{"httpMethod":"GET","path":"/cheques"}' \
  response.json

cat response.json
```

### Test EventBridge Rules

```bash
# Manually trigger reminder scheduler
aws lambda invoke \
  --function-name cheque-management-reminder-scheduler-dev \
  --payload '{}' \
  response.json
```

## 🔄 Updates and Maintenance

### Updating Lambda Code

```bash
# Update specific Lambda function
terraform apply -target=aws_lambda_function.cheques

# Update all Lambda functions
terraform apply -target=aws_lambda_function
```

### Updating Infrastructure

```bash
# Plan changes
terraform plan

# Apply changes
terraform apply

# Target specific resource
terraform apply -target=aws_dynamodb_table.main
```

### Rollback

```bash
# View state history
terraform state list

# Rollback to previous state (if using remote backend with versioning)
# Manually restore from S3 version or use:
terraform state pull > backup.tfstate
```

## 🗑️ Cleanup

### Destroy All Resources

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Warning**: This will permanently delete:
- All data in DynamoDB
- All files in S3
- All CloudWatch logs
- Cognito users

### Selective Cleanup

```bash
# Destroy specific resource
terraform destroy -target=aws_lambda_function.ml_forecast
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Lambda Function Not Found Error

**Error**: `Error: error creating Lambda Function: InvalidParameterValueException: Could not find file`

**Solution**: Create placeholder ZIP files (see Lambda Function Deployment section)

#### 2. SES Email Not Sending

**Error**: `MessageRejected: Email address is not verified`

**Solution**: Verify sender email in SES Console (see Post-Deployment Configuration)

#### 3. API Gateway 403 Forbidden

**Error**: `{"message":"Forbidden"}`

**Solution**: Check JWT token is valid and included in Authorization header

#### 4. DynamoDB Throttling

**Error**: `ProvisionedThroughputExceededException`

**Solution**: Switch to on-demand billing or increase provisioned capacity

#### 5. Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**: 
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Debug Commands

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply

# Check AWS CLI configuration
aws sts get-caller-identity

# Validate IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:user/USERNAME \
  --action-names lambda:CreateFunction dynamodb:CreateTable

# Check resource status
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `cheque-management`)].FunctionName'
```

## 📚 Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [DynamoDB Single Table Design](https://aws.amazon.com/blogs/compute/creating-a-single-table-design-with-amazon-dynamodb/)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review CloudWatch Logs for error details
3. Check AWS Service Health Dashboard
4. Review Terraform plan output carefully

## 📄 License

This infrastructure code is part of the Cheque Management System project.

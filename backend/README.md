# Cheque Management System - Backend

## 📋 Overview

This is the **serverless backend infrastructure** for the Cheque Management System, built on AWS using best practices from the AWS Well-Architected Framework. The system provides a complete REST API for managing supplier cheques, tracking bank balances, automating payment reminders, processing cheque images with OCR, and generating ML-based cash flow forecasts.

**Architecture Style**: Serverless, Event-Driven, Cost-Optimized  
**Infrastructure as Code**: Terraform  
**Runtime**: Node.js 18.x  
**Estimated Cost**: $8-15/month for low traffic

---

## 🏗️ Architecture Components

### Core AWS Services
- **Amazon Cognito**: User authentication & JWT tokens
- **API Gateway**: REST API with JWT authorizer
- **AWS Lambda**: 9 serverless functions for business logic
- **DynamoDB**: Single-table design for all data
- **S3**: Encrypted storage for images and reports
- **Amazon Textract**: OCR for cheque processing
- **EventBridge**: Scheduled triggers (daily reminders, weekly forecasts)
- **SNS + SES**: Email notification delivery
- **CloudWatch**: Logging, metrics, and alarms
- **X-Ray**: Distributed tracing

### Lambda Functions
1. **Cheques**: CRUD operations for cheques
2. **Suppliers**: Supplier management
3. **Bank Accounts**: Account and transaction management
4. **Notifications**: In-app notification management
5. **Reports**: Excel report generation
6. **Forecasts**: ML forecast retrieval
7. **Textract Processor**: OCR processing (S3 triggered)
8. **Reminder Scheduler**: Daily reminder job (EventBridge triggered)
9. **ML Forecast**: Weekly forecast generation (EventBridge triggered)

---

## 📁 Project Structure

```
backend/
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Provider and backend configuration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── cognito.tf             # Cognito User Pool
│   ├── dynamodb.tf            # DynamoDB table
│   ├── s3.tf                  # S3 buckets
│   ├── iam.tf                 # IAM roles and policies
│   ├── lambda.tf              # Lambda functions
│   ├── api_gateway.tf         # API Gateway REST API
│   ├── eventbridge.tf         # EventBridge rules
│   ├── sns_ses.tf             # SNS topics and SES
│   ├── cloudwatch.tf          # CloudWatch alarms and dashboard
│   ├── modules/
│   │   └── cors/              # Reusable CORS module
│   └── README.md              # Terraform deployment guide
├── lambda/                     # Lambda function code (to be created)
│   ├── functions/             # Individual function code
│   │   ├── cheques/
│   │   ├── suppliers/
│   │   ├── bank-accounts/
│   │   ├── notifications/
│   │   ├── reports/
│   │   ├── forecasts/
│   │   ├── textract-processor/
│   │   ├── reminder-scheduler/
│   │   └── ml-forecast/
│   └── layers/                # Shared dependencies
│       └── dependencies/
├── ARCHITECTURE.md             # Detailed architecture documentation
├── MANUAL_DEPLOYMENT_GUIDE.md  # Step-by-step console deployment
└── README.md                   # This file
```

---

## 🚀 Quick Start

### Prerequisites
- AWS Account with appropriate permissions
- Terraform v1.5.0 or later
- AWS CLI v2.x configured
- Node.js v18.x (for Lambda development)

### Option 1: Terraform Deployment (Recommended)

```bash
# 1. Navigate to terraform directory
cd backend/terraform

# 2. Create terraform.tfvars with your configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Initialize Terraform
terraform init

# 4. Review the plan
terraform plan

# 5. Deploy infrastructure
terraform apply

# 6. Save outputs for frontend configuration
terraform output -json > outputs.json
```

**See [terraform/README.md](terraform/README.md) for detailed instructions.**

### Option 2: Manual Console Deployment

Follow the step-by-step guide in [MANUAL_DEPLOYMENT_GUIDE.md](MANUAL_DEPLOYMENT_GUIDE.md) to deploy via AWS Console.

**Estimated time**: 2-3 hours

---

## 📝 Configuration

### Environment Variables

Create `terraform/terraform.tfvars`:

```hcl
# Basic Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "cheque-management"

# SES Configuration (IMPORTANT: Verify email in AWS Console)
ses_sender_email   = "noreply@yourdomain.com"
notification_email = "admin@yourdomain.com"

# CORS Configuration (Update with your frontend URL)
cors_allowed_origins = [
  "http://localhost:5173",
  "https://your-frontend-domain.com"
]

# Tags
common_tags = {
  Project     = "Cheque Management System"
  Environment = "dev"
  ManagedBy   = "Terraform"
}
```

### Frontend Integration

After deployment, configure your frontend with these values:

```env
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=<from terraform output>
VITE_COGNITO_CLIENT_ID=<from terraform output>
VITE_API_ENDPOINT=<from terraform output>
VITE_S3_BUCKET=<from terraform output>
```

Get values from Terraform:
```bash
terraform output -json environment_config
```

---

## 🔐 Post-Deployment Setup

### 1. Verify SES Email Address

**CRITICAL**: SES starts in sandbox mode. Verify your sender email:

```bash
aws ses verify-email-identity --email-address noreply@yourdomain.com
```

Or via AWS Console:
1. Go to SES Console → Email Addresses
2. Click "Verify a New Email Address"
3. Check inbox and click verification link

### 2. Create Test User

```bash
# Get User Pool ID
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)

# Create user
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

### 3. Request SES Production Access (for production)

1. Go to SES Console → Sending Statistics
2. Click "Request Production Access"
3. Fill out form (typically approved in 24-48 hours)

---

## 📊 Monitoring

### CloudWatch Dashboard

Access the dashboard:
```bash
DASHBOARD_NAME=$(terraform output -raw cloudwatch_dashboard_name)
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=$DASHBOARD_NAME"
```

### View Logs

```bash
# Cheques Lambda logs
aws logs tail /aws/lambda/cheque-management-cheques-dev --follow

# All Lambda errors
aws logs tail --follow --filter-pattern "ERROR"
```

### CloudWatch Alarms

Alarms are configured for:
- Lambda errors (> 5 in 5 minutes)
- API Gateway 5xx errors (> 10 in 5 minutes)
- DynamoDB throttles
- SES bounce rate (> 5%)

---

## 💰 Cost Estimation

### Monthly Cost (Low Traffic: ~1000 requests/day)

| Service | Cost |
|---------|------|
| API Gateway | $0.03 |
| Lambda | $0.60 |
| DynamoDB | $0.38 |
| S3 | $0.25 |
| Cognito | $0.28 |
| CloudWatch | $5.00 |
| SES | $0.10 |
| Textract | $1.50 |
| **Total** | **~$8.14/month** |

### Cost Optimization Tips

1. Reduce log retention to 7 days for dev
2. Disable X-Ray in dev environments
3. Use S3 lifecycle policies (Glacier after 365 days)
4. Right-size Lambda memory based on usage
5. Enable API Gateway caching for frequently accessed endpoints

---

## 🔒 Security Features

### Implemented Security Measures

✅ **Encryption**
- DynamoDB: Encryption at rest (AWS managed keys)
- S3: SSE-S3 encryption
- API Gateway: HTTPS only
- SES: TLS required

✅ **Authentication & Authorization**
- Cognito: Password policy, MFA support
- API Gateway: JWT authorizer
- Lambda: userId-based data isolation

✅ **IAM Least Privilege**
- Each Lambda has minimal required permissions
- No wildcard (*) permissions

✅ **Network Security**
- S3: Block all public access
- API Gateway: JWT required for all endpoints

✅ **Audit Trail**
- CloudWatch Logs for all API calls
- X-Ray tracing for request flow
- Transaction records for balance changes

---

## 🧪 Testing

### Test API Endpoint

```bash
# Get API URL
API_URL=$(terraform output -raw api_gateway_invoke_url)

# Test with authentication
curl -H "Authorization: Bearer $JWT_TOKEN" \
  $API_URL/v1/cheques
```

### Test Lambda Function

```bash
aws lambda invoke \
  --function-name cheque-management-cheques-dev \
  --payload '{"httpMethod":"GET","path":"/cheques"}' \
  response.json
```

---

## 🔄 Updates & Maintenance

### Update Lambda Code

```bash
# Update specific function
terraform apply -target=aws_lambda_function.cheques

# Update all functions
terraform apply
```

### Update Infrastructure

```bash
# Plan changes
terraform plan

# Apply changes
terraform apply
```

---

## 🗑️ Cleanup

### Destroy All Resources

```bash
cd backend/terraform
terraform destroy
```

**Warning**: This permanently deletes all data!

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: Lambda function not found error  
**Solution**: Create placeholder ZIP files (see terraform/README.md)

**Issue**: SES email not sending  
**Solution**: Verify sender email in SES Console

**Issue**: API returns 403 Forbidden  
**Solution**: Check JWT token is valid and in Authorization header

**Issue**: DynamoDB throttling  
**Solution**: Already using on-demand billing, check for hot partitions

---

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Detailed architecture documentation
- **[terraform/README.md](terraform/README.md)**: Terraform deployment guide
- **[MANUAL_DEPLOYMENT_GUIDE.md](MANUAL_DEPLOYMENT_GUIDE.md)**: Console deployment guide

---

## 🎯 Key Design Decisions

### Why Serverless?
- Zero server management
- Auto-scaling
- Pay-per-use pricing
- High availability built-in

### Why Single Table Design (DynamoDB)?
- Cost optimization (one table = one set of capacity units)
- Performance (related data in same partition)
- Simplicity (fewer tables to manage)

### Why Pre-Signed URLs for S3?
- Security (no public access)
- Performance (direct upload, no Lambda proxy)
- Cost (no data transfer through Lambda)

### Why EventBridge over CloudWatch Events?
- Modern service (evolution of CloudWatch Events)
- Better filtering and schema registry
- Third-party integrations

---

## 🔮 Future Enhancements

### Phase 2 Features
- SageMaker DeepAR integration for ML forecasting
- Anomaly detection for unusual spending patterns
- Multi-currency support
- Batch operations for bulk import/export
- Advanced reporting with custom templates

### Scalability Improvements
- DynamoDB GSIs for complex queries
- Lambda provisioned concurrency
- API Gateway caching
- CloudFront CDN for global delivery

### Security Enhancements
- AWS WAF for API protection
- Secrets Manager for credential rotation
- GuardDuty for threat detection
- AWS Config for compliance monitoring

---

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section
2. Review CloudWatch Logs for errors
3. Check AWS Service Health Dashboard
4. Review Terraform plan output

---

## 📄 License

This project is part of the Cheque Management System.

---

## 🙏 Acknowledgments

Built following AWS Well-Architected Framework principles:
- Operational Excellence
- Security
- Reliability
- Performance Efficiency
- Cost Optimization

---

**Ready to deploy?** Start with [terraform/README.md](terraform/README.md) or [MANUAL_DEPLOYMENT_GUIDE.md](MANUAL_DEPLOYMENT_GUIDE.md)!

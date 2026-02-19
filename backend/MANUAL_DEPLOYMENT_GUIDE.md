# 🎯 Manual AWS Console Deployment Guide

## Overview

This guide walks you through deploying the Cheque Management System backend **manually via AWS Console**. While Terraform automates this process, this guide is for those who prefer or need to deploy via the console.

**Estimated Time**: 2-3 hours  
**Difficulty**: Intermediate  
**Cost**: ~$8-15/month for low traffic

---

## 📋 Prerequisites

- AWS Account with admin access
- Basic understanding of AWS services
- Email address for SES verification
- Frontend application ready for integration

---

## 🚀 Deployment Steps

### Phase 1: Core Infrastructure (30 minutes)

#### Step 1.1: Create DynamoDB Table

**Purpose**: Single table for all data storage

1. Go to **DynamoDB Console** → **Tables** → **Create table**

2. **Table settings**:
   - Table name: `FinanceSystemTable-dev`
   - Partition key: `PK` (String)
   - Sort key: `SK` (String)

3. **Table settings**:
   - Table class: **DynamoDB Standard**
   - Capacity mode: **On-demand**

4. **Encryption**:
   - Encryption at rest: **Owned by Amazon DynamoDB**

5. **Point-in-time recovery**:
   - Enable: **Yes** ✅

6. Click **Create table**

**Reasoning**: 
- On-demand billing = no capacity planning, pay per request
- Single table design = cost-effective, efficient queries
- Point-in-time recovery = data protection for financial records

---

#### Step 1.2: Create S3 Bucket

**Purpose**: Store cheque images and reports

1. Go to **S3 Console** → **Create bucket**

2. **General configuration**:
   - Bucket name: `cheque-management-images-dev-[YOUR-ACCOUNT-ID]`
   - AWS Region: `us-east-1` (or your preferred region)

3. **Object Ownership**:
   - ACLs disabled (recommended) ✅

4. **Block Public Access**:
   - Block all public access: **ON** ✅ (CRITICAL for security)

5. **Bucket Versioning**:
   - Disable (optional: enable for audit trail)

6. **Default encryption**:
   - Encryption type: **Server-side encryption with Amazon S3 managed keys (SSE-S3)**
   - Bucket Key: **Enable** ✅

7. Click **Create bucket**

8. **Configure Lifecycle Rule** (optional but recommended):
   - Go to bucket → **Management** → **Create lifecycle rule**
   - Rule name: `archive-old-images`
   - Rule scope: **Apply to all objects**
   - Lifecycle rule actions:
     - ✅ Transition current versions of objects between storage classes
     - Days after object creation: `365`
     - Storage class: **Glacier Flexible Retrieval**
   - Click **Create rule**

**Reasoning**:
- Block public access = security (financial documents must be private)
- SSE-S3 = encryption at rest without KMS cost
- Lifecycle to Glacier = cost optimization ($0.023/GB → $0.004/GB)

---

#### Step 1.3: Create Cognito User Pool

**Purpose**: User authentication and JWT tokens

1. Go to **Cognito Console** → **User pools** → **Create user pool**

2. **Step 1: Configure sign-in experience**:
   - Provider types: **Cognito user pool** ✅
   - Cognito user pool sign-in options:
     - ✅ Email
   - Click **Next**

3. **Step 2: Configure security requirements**:
   - Password policy:
     - Password policy mode: **Cognito defaults**
     - OR Custom:
       - Minimum length: `8`
       - ✅ Require uppercase, lowercase, numbers, symbols
   - Multi-factor authentication:
     - MFA enforcement: **Optional MFA**
     - MFA methods: ✅ **Authenticator apps**
   - User account recovery:
     - ✅ Enable self-service account recovery
     - Delivery method: **Email only**
   - Click **Next**

4. **Step 3: Configure sign-up experience**:
   - Self-service sign-up: **Enable** ✅
   - Attribute verification: **Send email message, verify email address** ✅
   - Required attributes:
     - ✅ email
   - Click **Next**

5. **Step 4: Configure message delivery**:
   - Email provider: **Send email with Cognito**
   - FROM email address: `no-reply@verificationemail.com` (default)
   - Click **Next**

6. **Step 5: Integrate your app**:
   - User pool name: `cheque-management-user-pool-dev`
   - Hosted authentication pages: **Use the Cognito Hosted UI** (optional)
   - Domain: `cheque-mgmt-dev-[random]` (if using Hosted UI)
   - Initial app client:
     - App client name: `web-client`
     - Client secret: **Don't generate a client secret** ✅
     - Authentication flows:
       - ✅ ALLOW_USER_PASSWORD_AUTH
       - ✅ ALLOW_REFRESH_TOKEN_AUTH
   - Click **Next**

7. **Step 6: Review and create**:
   - Review settings
   - Click **Create user pool**

8. **Save these values** (you'll need them later):
   - User Pool ID: `us-east-1_xxxxxxxxx`
   - App Client ID: `xxxxxxxxxxxxxxxxxxxxxxxxxx`

**Reasoning**:
- Email sign-in = user-friendly, no username to remember
- Optional MFA = security without forcing all users
- No client secret = suitable for frontend apps (can't keep secrets)

---

### Phase 2: API Gateway & Lambda (60 minutes)

#### Step 2.1: Create IAM Roles for Lambda

**Purpose**: Grant Lambda functions permissions to access AWS services

**For each Lambda function, create a role:**

1. Go to **IAM Console** → **Roles** → **Create role**

2. **Trusted entity type**: **AWS service**
   - Use case: **Lambda** ✅

3. **Add permissions**:
   - For **Cheques Lambda**:
     - `AWSLambdaBasicExecutionRole` (managed policy)
     - Create inline policy:
       ```json
       {
         "Version": "2012-10-17",
         "Statement": [
           {
             "Effect": "Allow",
             "Action": [
               "dynamodb:GetItem",
               "dynamodb:PutItem",
               "dynamodb:UpdateItem",
               "dynamodb:Query"
             ],
             "Resource": "arn:aws:dynamodb:us-east-1:ACCOUNT_ID:table/FinanceSystemTable-dev"
           },
           {
             "Effect": "Allow",
             "Action": [
               "s3:PutObject",
               "s3:GetObject"
             ],
             "Resource": "arn:aws:s3:::cheque-management-images-dev-ACCOUNT_ID/*"
           },
           {
             "Effect": "Allow",
             "Action": [
               "xray:PutTraceSegments",
               "xray:PutTelemetryRecords"
             ],
             "Resource": "*"
           }
         ]
       }
       ```

4. **Role name**: `cheque-management-cheques-lambda-role-dev`

5. Click **Create role**

**Repeat for other Lambda functions** with appropriate permissions:
- **Suppliers Lambda**: DynamoDB only
- **Bank Accounts Lambda**: DynamoDB only
- **Notifications Lambda**: DynamoDB only
- **Reports Lambda**: DynamoDB + S3
- **Forecasts Lambda**: DynamoDB only
- **Textract Processor**: DynamoDB + S3 + Textract
- **Reminder Scheduler**: DynamoDB + SNS
- **ML Forecast**: DynamoDB

**Reasoning**: Least privilege principle - each function only gets permissions it needs

---

#### Step 2.2: Create Lambda Functions

**Purpose**: Business logic for each domain

**For each function, follow these steps:**

1. Go to **Lambda Console** → **Functions** → **Create function**

2. **Basic information**:
   - Function name: `cheque-management-cheques-dev`
   - Runtime: **Node.js 18.x**
   - Architecture: **x86_64**
   - Permissions: **Use an existing role**
   - Existing role: Select the role created in Step 2.1

3. Click **Create function**

4. **Configure function**:
   - **Code**: Upload your Lambda code (ZIP file)
   - **Runtime settings**:
     - Handler: `index.handler`
   - **General configuration**:
     - Memory: `512 MB`
     - Timeout: `30 seconds`
   - **Environment variables**:
     ```
     TABLE_NAME = FinanceSystemTable-dev
     S3_BUCKET_NAME = cheque-management-images-dev-ACCOUNT_ID
     PRESIGNED_URL_EXPIRY = 900
     ENVIRONMENT = dev
     LOG_LEVEL = DEBUG
     ```
   - **Monitoring and operations tools**:
     - ✅ Enable active tracing (X-Ray)

5. Click **Deploy**

**Create these Lambda functions**:
1. `cheque-management-cheques-dev` (512 MB, 30s)
2. `cheque-management-suppliers-dev` (256 MB, 30s)
3. `cheque-management-bank-accounts-dev` (256 MB, 30s)
4. `cheque-management-notifications-dev` (256 MB, 30s)
5. `cheque-management-reports-dev` (1024 MB, 60s)
6. `cheque-management-forecasts-dev` (256 MB, 30s)
7. `cheque-management-textract-processor-dev` (512 MB, 60s)
8. `cheque-management-reminder-scheduler-dev` (512 MB, 300s)
9. `cheque-management-ml-forecast-dev` (1024 MB, 300s)

**Reasoning**:
- Node.js 18.x = latest LTS, best performance
- Memory sizing = cost optimization (pay for what you need)
- X-Ray tracing = debugging and performance monitoring

---

#### Step 2.3: Create API Gateway

**Purpose**: REST API with JWT authorization

1. Go to **API Gateway Console** → **Create API**

2. Choose **REST API** (not Private or HTTP API)
   - Click **Build**

3. **Create new API**:
   - Choose: **New API**
   - API name: `cheque-management-api-dev`
   - Description: `Cheque Management System REST API`
   - Endpoint Type: **Regional**

4. Click **Create API**

5. **Create Authorizer**:
   - Click **Authorizers** → **Create New Authorizer**
   - Name: `cognito-authorizer`
   - Type: **Cognito**
   - Cognito User Pool: Select your user pool
   - Token Source: `Authorization`
   - Click **Create**

6. **Create Resources and Methods**:

   **Create `/v1` resource**:
   - Actions → **Create Resource**
   - Resource Name: `v1`
   - Resource Path: `/v1`
   - ✅ Enable API Gateway CORS
   - Click **Create Resource**

   **Create `/v1/cheques` resource**:
   - Select `/v1` → Actions → **Create Resource**
   - Resource Name: `cheques`
   - ✅ Enable API Gateway CORS
   - Click **Create Resource**

   **Create GET method for `/v1/cheques`**:
   - Select `/v1/cheques` → Actions → **Create Method** → **GET**
   - Integration type: **Lambda Function**
   - ✅ Use Lambda Proxy integration
   - Lambda Function: `cheque-management-cheques-dev`
   - Click **Save** → **OK** (grant permission)

   **Configure Method Request**:
   - Click **Method Request**
   - Authorization: **cognito-authorizer** ✅
   - API Key Required: **false**

   **Create POST method for `/v1/cheques`**:
   - Repeat above steps for POST method

   **Repeat for all endpoints**:
   - `/v1/cheques` - GET, POST
   - `/v1/cheques/{chequeId}` - GET, PUT, DELETE
   - `/v1/cheques/{chequeId}/upload-url` - POST
   - `/v1/cheques/{chequeId}/status` - PUT
   - `/v1/suppliers` - GET, POST
   - `/v1/suppliers/{supplierId}` - GET, PUT, DELETE
   - `/v1/bank-accounts` - GET, POST
   - `/v1/bank-accounts/{accountId}` - GET, PUT, DELETE
   - `/v1/bank-accounts/{accountId}/transactions` - GET
   - `/v1/notifications` - GET
   - `/v1/notifications/{notificationId}/read` - PUT
   - `/v1/reports/export` - POST
   - `/v1/forecasts` - GET
   - `/v1/forecasts/{dateRange}` - GET

7. **Deploy API**:
   - Actions → **Deploy API**
   - Deployment stage: **[New Stage]**
   - Stage name: `dev`
   - Click **Deploy**

8. **Configure Stage Settings**:
   - Click **Stages** → **dev**
   - **Settings** tab:
     - ✅ Enable CloudWatch Logs
     - Log level: **INFO**
     - ✅ Log full requests/responses data
     - ✅ Enable Detailed CloudWatch Metrics
     - ✅ Enable X-Ray Tracing
   - **Throttle Settings**:
     - Rate: `2000` requests per second
     - Burst: `5000` requests

9. **Save Invoke URL**: `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev`

**Reasoning**:
- REST API = full feature set, request/response pattern
- Cognito authorizer = JWT validation at API Gateway (not Lambda)
- Lambda proxy integration = pass full request to Lambda
- CORS enabled = frontend can call API from different origin

---

### Phase 3: Event-Driven Workflows (30 minutes)

#### Step 3.1: Create SNS Topic

**Purpose**: Pub/Sub for email notifications

1. Go to **SNS Console** → **Topics** → **Create topic**

2. **Details**:
   - Type: **Standard**
   - Name: `cheque-reminders-dev`
   - Display name: `Cheque Payment Reminders`

3. **Encryption**: (optional)
   - ✅ Enable encryption
   - AWS KMS key: **Default**

4. Click **Create topic**

5. **Save Topic ARN**: `arn:aws:sns:us-east-1:ACCOUNT_ID:cheque-reminders-dev`

**Reasoning**: SNS decouples Lambda from SES, enables fan-out pattern

---

#### Step 3.2: Configure SES

**Purpose**: Send email notifications

1. Go to **SES Console** → **Verified identities** → **Create identity**

2. **Identity type**: **Email address**
   - Email address: `noreply@yourdomain.com`

3. Click **Create identity**

4. **Verify email**:
   - Check your inbox
   - Click verification link

5. **Request Production Access** (for production):
   - SES Console → **Account dashboard**
   - Click **Request production access**
   - Fill out form (approved in 24-48 hours)

**Reasoning**: SES sandbox mode requires verified recipients, production mode allows any recipient

---

#### Step 3.3: Create EventBridge Rules

**Purpose**: Schedule Lambda functions

**Daily Reminder Rule**:

1. Go to **EventBridge Console** → **Rules** → **Create rule**

2. **Define rule detail**:
   - Name: `cheque-reminder-daily-dev`
   - Description: `Trigger daily cheque reminder check`
   - Event bus: **default**
   - Rule type: **Schedule**

3. **Define schedule**:
   - Schedule pattern: **Cron-based schedule**
   - Cron expression: `0 9 * * ? *` (9 AM UTC daily)

4. **Select target**:
   - Target types: **AWS service**
   - Select a target: **Lambda function**
   - Function: `cheque-management-reminder-scheduler-dev`

5. **Configure retry policy**:
   - Maximum age of event: `3600` seconds (1 hour)
   - Retry attempts: `2`

6. Click **Create rule**

**Weekly ML Forecast Rule**:

1. Repeat above steps with:
   - Name: `ml-forecast-weekly-dev`
   - Cron: `0 2 ? * SUN *` (2 AM UTC every Sunday)
   - Target: `cheque-management-ml-forecast-dev`

**Reasoning**: EventBridge = modern, flexible scheduling (replaces CloudWatch Events)

---

#### Step 3.4: Configure S3 Event Notification

**Purpose**: Trigger Textract Lambda on image upload

1. Go to **S3 Console** → Select your bucket

2. **Properties** tab → **Event notifications** → **Create event notification**

3. **General configuration**:
   - Event name: `textract-trigger`
   - Prefix: (leave empty or use `*/cheques/`)
   - Suffix: `.jpg`

4. **Event types**:
   - ✅ All object create events

5. **Destination**:
   - Destination: **Lambda function**
   - Lambda function: `cheque-management-textract-processor-dev`

6. Click **Save changes**

**Reasoning**: S3 events = real-time processing, no polling needed

---

### Phase 4: Monitoring & Observability (20 minutes)

#### Step 4.1: Create CloudWatch Alarms

**Lambda Error Alarm**:

1. Go to **CloudWatch Console** → **Alarms** → **Create alarm**

2. **Select metric**:
   - Namespace: **AWS/Lambda**
   - Metric name: **Errors**
   - Dimensions: FunctionName = `cheque-management-cheques-dev`

3. **Specify metric and conditions**:
   - Statistic: **Sum**
   - Period: **5 minutes**
   - Threshold type: **Static**
   - Whenever Errors is: **Greater** than `5`

4. **Configure actions**:
   - Alarm state trigger: **In alarm**
   - Send notification to: (create SNS topic for alarms)

5. **Name and description**:
   - Alarm name: `cheque-lambda-errors-dev`

6. Click **Create alarm**

**Repeat for**:
- API Gateway 5xx errors (> 10 in 5 min)
- DynamoDB throttles (> 10 in 5 min)
- Lambda throttles (> 10 in 5 min)

**Reasoning**: Proactive monitoring = catch issues before users report them

---

#### Step 4.2: Create CloudWatch Dashboard

1. Go to **CloudWatch Console** → **Dashboards** → **Create dashboard**

2. **Dashboard name**: `cheque-management-dev`

3. **Add widgets**:
   - **Lambda Invocations**: Line graph, all Lambda functions
   - **Lambda Errors**: Line graph, all Lambda functions
   - **API Gateway Requests**: Line graph, Count metric
   - **DynamoDB Capacity**: Line graph, ConsumedReadCapacityUnits

4. Click **Create dashboard**

**Reasoning**: Single pane of glass for system health

---

### Phase 5: Testing & Validation (20 minutes)

#### Step 5.1: Create Test User

1. Go to **Cognito Console** → Your user pool → **Users** → **Create user**

2. **User information**:
   - Username: `admin@example.com`
   - Email: `admin@example.com`
   - ✅ Mark email as verified
   - Temporary password: `TempPassword123!`

3. Click **Create user**

4. **Set permanent password** (via AWS CLI):
   ```bash
   aws cognito-idp admin-set-user-password \
     --user-pool-id us-east-1_xxxxxxxxx \
     --username admin@example.com \
     --password YourSecurePassword123! \
     --permanent
   ```

---

#### Step 5.2: Test API Endpoints

1. **Get JWT Token**:
   - Use Postman or frontend to authenticate
   - Or use AWS CLI:
     ```bash
     aws cognito-idp initiate-auth \
       --auth-flow USER_PASSWORD_AUTH \
       --client-id YOUR_CLIENT_ID \
       --auth-parameters USERNAME=admin@example.com,PASSWORD=YourSecurePassword123!
     ```

2. **Test API**:
   ```bash
   curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev/v1/cheques
   ```

---

## 📝 Configuration Summary

After deployment, save these values for frontend configuration:

```env
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_API_ENDPOINT=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev
VITE_S3_BUCKET=cheque-management-images-dev-ACCOUNT_ID
```

---

## 💰 Cost Optimization Tips

1. **Reduce log retention**: CloudWatch Logs → 7 days for dev
2. **Disable X-Ray in dev**: Remove active tracing
3. **Use S3 Intelligent-Tiering**: Automatic cost optimization
4. **Right-size Lambda memory**: Monitor and adjust based on usage
5. **Enable API Gateway caching**: For frequently accessed endpoints

---

## 🔒 Security Checklist

- ✅ S3 bucket has block public access enabled
- ✅ DynamoDB encryption at rest enabled
- ✅ API Gateway uses JWT authorizer
- ✅ Lambda functions have least privilege IAM roles
- ✅ SES sender email verified
- ✅ CloudWatch Logs enabled for all services
- ✅ X-Ray tracing enabled
- ✅ MFA enabled for Cognito (optional but recommended)

---

## 🐛 Troubleshooting

### Issue: API returns 403 Forbidden
**Solution**: Check JWT token is valid and included in Authorization header

### Issue: Lambda function timeout
**Solution**: Increase timeout in Lambda configuration (max 15 minutes)

### Issue: SES email not sending
**Solution**: Verify sender email in SES Console, check sandbox mode

### Issue: DynamoDB throttling
**Solution**: Switch to on-demand billing mode

---

## 📚 Next Steps

1. Deploy Lambda function code
2. Configure frontend with AWS credentials
3. Test end-to-end workflows
4. Set up CI/CD pipeline
5. Enable additional monitoring
6. Request SES production access

---

## 🎉 Congratulations!

You've successfully deployed the Cheque Management System backend manually via AWS Console. The infrastructure is now ready for integration with your frontend application.

**Total Resources Created**: ~40 AWS resources  
**Deployment Time**: 2-3 hours  
**Monthly Cost**: ~$8-15 for low traffic


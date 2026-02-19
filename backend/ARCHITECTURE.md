# 🏗️ Cheque Management System - Architecture Documentation

## System Overview

The Cheque Management System is a **serverless, event-driven** backend built on AWS infrastructure following the **AWS Well-Architected Framework**. The system manages supplier cheques, tracks bank account balances, automates payment reminders, processes cheque images with OCR, and provides ML-based cash flow forecasting.

---

## 🎯 Architecture Principles

### 1. Serverless-First
- **Zero server management**: All compute is serverless (Lambda)
- **Auto-scaling**: Scales automatically with demand
- **Pay-per-use**: Only pay for actual usage

### 2. Event-Driven
- **Asynchronous processing**: S3 events trigger OCR
- **Scheduled workflows**: EventBridge triggers reminders and forecasts
- **Decoupled components**: SNS for pub/sub messaging

### 3. Security by Design
- **Encryption everywhere**: At rest (DynamoDB, S3) and in transit (HTTPS, TLS)
- **Least privilege IAM**: Each Lambda has minimal required permissions
- **Private resources**: S3 blocks public access, API requires JWT

### 4. Cost Optimization
- **Single table design**: One DynamoDB table reduces costs
- **On-demand billing**: Pay per request, no idle capacity
- **Lifecycle policies**: Move old data to cheaper storage (Glacier)

### 5. Observability
- **Comprehensive logging**: CloudWatch Logs for all services
- **Distributed tracing**: X-Ray for request flow visualization
- **Proactive monitoring**: CloudWatch Alarms for key metrics

---

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Frontend Application                        │
│                     (React + TypeScript + Vite)                      │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTPS + JWT
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Amazon Cognito User Pool                        │
│                    (Authentication & JWT Tokens)                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Amazon API Gateway (REST)                       │
│                      JWT Authorizer + CORS                           │
│  Routes: /cheques, /suppliers, /bank-accounts, /notifications,      │
│          /reports, /forecasts                                        │
└──┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┘
   │          │          │          │          │          │
   ▼          ▼          ▼          ▼          ▼          ▼
┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
│Cheque│  │Suppl │  │ Bank │  │Notif │  │Report│  │Forec │
│Lambda│  │Lambda│  │Lambda│  │Lambda│  │Lambda│  │Lambda│
└──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘
   │         │         │         │         │         │
   └─────────┴─────────┴─────────┴─────────┴─────────┘
                       │
                       ▼
        ┌──────────────────────────────────┐
        │   Amazon DynamoDB (Single Table) │
        │   FinanceSystemTable             │
        │   PK: Partition Key              │
        │   SK: Sort Key                   │
        └──────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      Event-Driven Workflows                          │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│  Amazon S3       │ Event   │  Textract        │
│  (Cheque Images) ├────────►│  Lambda          │
│                  │         │  (OCR Processing)│
└──────────────────┘         └──────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────┐
│  EventBridge     │ Daily   │  Reminder        │  Pub    │  Amazon  │
│  (Cron: Daily)   ├────────►│  Lambda          ├────────►│  SNS     │
│                  │         │                  │         └────┬─────┘
└──────────────────┘         └──────────────────┘              │
                                                                ▼
                                                         ┌──────────────┐
                                                         │  Amazon SES  │
                                                         │  (Email)     │
                                                         └──────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────┐
│  EventBridge     │ Weekly  │  ML Forecast     │  Batch  │ SageMaker│
│  (Cron: Weekly)  ├────────►│  Lambda          ├────────►│ Forecast │
│                  │         │                  │         └──────────┘
└──────────────────┘         └──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      Monitoring & Observability                      │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  CloudWatch      │  │  CloudWatch      │  │  AWS X-Ray       │
│  Logs            │  │  Alarms          │  │  (Tracing)       │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 🔄 Data Flow Patterns

### 1. Cheque Creation Flow
```
User → Frontend → API Gateway (JWT validation) → Cheque Lambda
                                                      ↓
                                                  DynamoDB
                                                      ↓
                                                  Response
```

**Steps**:
1. User fills cheque form in frontend
2. Frontend sends POST request with JWT token
3. API Gateway validates JWT with Cognito
4. Cheque Lambda validates supplier and bank account exist
5. Lambda generates unique chequeId
6. Lambda stores cheque in DynamoDB with PK=USER#{userId}, SK=CHEQUE#{chequeId}
7. Lambda returns chequeId to frontend

**Key Design Decisions**:
- JWT validation at API Gateway (not Lambda) = lower latency
- Referential integrity check = prevent orphaned records
- Single table design = efficient queries

---

### 2. Image Upload & OCR Flow
```
User → Frontend → API Gateway → Cheque Lambda (generate pre-signed URL)
                                      ↓
                                  Response (URL)
                                      ↓
User → S3 (direct upload via pre-signed URL)
                                      ↓
                                  S3 Event
                                      ↓
                              Textract Lambda
                                      ↓
                              Textract Service
                                      ↓
                              Parse Results
                                      ↓
                              Update DynamoDB
```

**Steps**:
1. User requests upload URL for cheque image
2. Cheque Lambda generates pre-signed S3 URL (15 min expiry)
3. Frontend uploads image directly to S3 (no Lambda proxy)
4. S3 triggers Textract Lambda on ObjectCreated event
5. Textract Lambda calls AWS Textract DetectDocumentText API
6. Lambda parses response for cheque number, amount, date, payee
7. Lambda updates cheque record with extracted data

**Key Design Decisions**:
- Pre-signed URLs = direct S3 upload, no Lambda data transfer cost
- Asynchronous OCR = don't block user upload flow
- Error handling = log failures, don't fail if OCR incomplete

---

### 3. Cheque Clearance Flow (with Balance Update)
```
User → Frontend → API Gateway → Cheque Lambda
                                      ↓
                              Get Cheque Record
                                      ↓
                              Validate Status Transition
                                      ↓
                              DynamoDB Transaction:
                              1. Update Cheque Status
                              2. Deduct from Bank Balance
                              3. Create Transaction Record
                                      ↓
                              Response (success/failure)
```

**Steps**:
1. User marks cheque as "cleared"
2. Cheque Lambda retrieves cheque record
3. Lambda validates status transition (e.g., issued → cleared is valid)
4. Lambda uses DynamoDB TransactWriteItems for atomicity:
   - Update cheque status to "cleared"
   - Deduct amount from bank account balance
   - Create transaction record with previous/new balance
5. If any step fails, entire transaction rolls back
6. Lambda returns success response

**Key Design Decisions**:
- DynamoDB Transactions = ACID guarantees for financial operations
- Status transition validation = prevent invalid state changes
- Transaction audit trail = immutable record of balance changes

---

### 4. Daily Reminder Flow
```
EventBridge (9 AM UTC) → Reminder Lambda
                              ↓
                      Query DynamoDB (upcoming cheques)
                              ↓
                      For each cheque:
                      1. Create Notification Record
                      2. Publish to SNS
                              ↓
                      SNS → SES → Email
```

**Steps**:
1. EventBridge triggers Reminder Lambda daily at 9 AM UTC
2. Lambda calculates target dates (today + 5 days, today + 1 day)
3. Lambda queries DynamoDB for cheques with matching dates
4. For each cheque:
   - Create in-app notification record
   - Publish message to SNS topic with cheque details
5. SNS delivers message to SES
6. SES sends formatted email to user

**Key Design Decisions**:
- EventBridge over CloudWatch Events = modern, flexible scheduling
- SNS intermediary = decouple Lambda from SES, enable fan-out
- In-app + email = multiple notification channels

---

### 5. Weekly ML Forecast Flow
```
EventBridge (2 AM UTC Sunday) → ML Forecast Lambda
                                      ↓
                              Query DynamoDB (historical cheques)
                                      ↓
                              Aggregate by date
                                      ↓
                              Phase 1: Simple forecasting
                              Phase 2: SageMaker DeepAR
                                      ↓
                              Store forecast in DynamoDB
```

**Steps**:
1. EventBridge triggers ML Forecast Lambda weekly
2. Lambda queries all cleared cheques for user
3. Lambda aggregates amounts by date (time-series data)
4. **Phase 1**: Calculate moving average, linear projection
5. **Phase 2**: Submit batch job to SageMaker DeepAR
6. Lambda stores forecast results in DynamoDB
7. Frontend retrieves forecast via Forecasts Lambda

**Key Design Decisions**:
- Two-phase approach = validate pipeline before ML complexity
- Batch transform over real-time endpoint = cost optimization
- Weekly schedule = balance freshness vs. cost

---

## 🗄️ Data Model (DynamoDB Single Table Design)

### Entity Patterns

| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| User Profile | USER#{userId} | PROFILE | email, name, createdAt |
| Supplier | USER#{userId} | SUPPLIER#{supplierId} | company, contactPerson, phone, email, paymentTermsDays |
| Bank Account | USER#{userId} | BANK#{accountId} | bankName, accountName, currentBalance, lastUpdated |
| Cheque | USER#{userId} | CHEQUE#{chequeId} | supplierId, chequeNumber, amount, chequeDate, bankAccountId, status, imageUrl |
| Notification | USER#{userId} | NOTIF#{timestamp} | message, chequeId, dateSent, type, read |
| Forecast | USER#{userId} | FORECAST#{dateRange} | predictions[], generatedAt |
| Transaction | USER#{userId} | TRANSACTION#{accountId}#{timestamp} | chequeId, amount, previousBalance, newBalance |

### Access Patterns

1. **Get user profile**: Query PK=USER#{userId}, SK=PROFILE
2. **List suppliers**: Query PK=USER#{userId}, SK begins_with SUPPLIER#
3. **Get specific supplier**: Query PK=USER#{userId}, SK=SUPPLIER#{supplierId}
4. **List cheques**: Query PK=USER#{userId}, SK begins_with CHEQUE#
5. **Get cheques by status**: Query + filter on status attribute
6. **List notifications**: Query PK=USER#{userId}, SK begins_with NOTIF#, sort descending
7. **Get transactions for account**: Query PK=USER#{userId}, SK begins_with TRANSACTION#{accountId}#

### Why Single Table Design?

**Benefits**:
- **Cost**: One table = one set of read/write capacity units
- **Performance**: Related data in same partition = faster queries
- **Simplicity**: Fewer tables to manage

**Trade-offs**:
- **Complexity**: Requires careful key design
- **Flexibility**: Harder to add new access patterns later

**When to use GSIs**: Only if query performance requires optimization (start without them)

---

## 🔐 Security Architecture

### Authentication & Authorization

```
User → Cognito (authenticate) → JWT Token
                                      ↓
User → API Gateway (validate JWT) → Lambda (extract userId)
                                      ↓
                              DynamoDB (filter by userId)
```

**Security Layers**:
1. **Cognito**: Password policy, MFA, email verification
2. **API Gateway**: JWT authorizer validates token before Lambda invocation
3. **Lambda**: Extracts userId from JWT, uses in all queries
4. **DynamoDB**: Data isolation via partition key (USER#{userId})

### Encryption

| Service | At Rest | In Transit |
|---------|---------|------------|
| DynamoDB | ✅ AWS managed keys | ✅ HTTPS |
| S3 | ✅ SSE-S3 | ✅ HTTPS |
| CloudWatch Logs | ✅ Default encryption | ✅ HTTPS |
| API Gateway | N/A | ✅ HTTPS |
| SES | N/A | ✅ TLS required |

### IAM Least Privilege

Each Lambda function has a dedicated IAM role with minimal permissions:

**Example: Cheques Lambda**
```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:UpdateItem",
    "dynamodb:Query"
  ],
  "Resource": "arn:aws:dynamodb:*:*:table/FinanceSystemTable"
}
```

**No wildcard (*) permissions** = principle of least privilege

---

## 📈 Scalability & Performance

### Auto-Scaling Components

| Service | Scaling Mechanism | Limits |
|---------|-------------------|--------|
| Lambda | Concurrent executions | 1000 (default), request increase |
| DynamoDB | On-demand auto-scaling | Unlimited (with throttling protection) |
| API Gateway | Automatic | 10,000 RPS (default), request increase |
| S3 | Automatic | Unlimited |

### Performance Optimizations

1. **Lambda**:
   - Memory sizing: 256 MB - 1024 MB based on function
   - Timeout: 30s - 300s based on operation
   - Provisioned concurrency: (optional) for critical functions

2. **DynamoDB**:
   - On-demand billing: No capacity planning
   - Consistent reads: For financial data
   - Batch operations: For bulk queries

3. **API Gateway**:
   - Lambda proxy integration: Minimal overhead
   - Caching: (optional) for frequently accessed endpoints
   - Throttling: Protect backend from spikes

4. **S3**:
   - Pre-signed URLs: Direct upload, no Lambda proxy
   - Transfer acceleration: (optional) for global users

---

## 💰 Cost Breakdown

### Monthly Cost Estimate (Low Traffic: ~1000 requests/day)

| Service | Usage | Cost |
|---------|-------|------|
| **API Gateway** | 30K requests | $0.03 |
| **Lambda** | 30K invocations, 512MB, 1s avg | $0.60 |
| **DynamoDB** | 30K reads, 10K writes | $0.38 |
| **S3** | 10GB storage, 1K uploads | $0.25 |
| **Cognito** | 50 MAU | $0.28 |
| **CloudWatch** | Logs + Metrics | $5.00 |
| **SES** | 1K emails | $0.10 |
| **Textract** | 100 pages | $1.50 |
| **X-Ray** | 30K traces | $0.15 |
| **EventBridge** | 60 invocations | $0.00 |
| **SNS** | 1K publishes | $0.00 |
| **Total** | | **~$8.29/month** |

### Cost Optimization Strategies

1. **Reduce log retention**: 30 days → 7 days = 75% savings
2. **Disable X-Ray in dev**: $0.15/month savings
3. **S3 Lifecycle to Glacier**: $0.023/GB → $0.004/GB (82% savings)
4. **Right-size Lambda memory**: Monitor and adjust
5. **API Gateway caching**: Reduce Lambda invocations

### Cost Scaling

| Traffic Level | Monthly Cost |
|---------------|--------------|
| Low (1K req/day) | $8-10 |
| Medium (10K req/day) | $30-40 |
| High (100K req/day) | $200-300 |

---

## 🔍 Monitoring & Observability

### CloudWatch Metrics

**Lambda Metrics**:
- Invocations
- Errors
- Throttles
- Duration
- Concurrent Executions

**API Gateway Metrics**:
- Count (total requests)
- 4XXError
- 5XXError
- Latency
- IntegrationLatency

**DynamoDB Metrics**:
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- ReadThrottleEvents
- WriteThrottleEvents

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| Lambda Errors | > 5 in 5 min | SNS notification |
| Lambda Throttles | > 10 in 5 min | SNS notification |
| API 5xx Errors | > 10 in 5 min | SNS notification |
| API Latency | > 2 seconds | SNS notification |
| DynamoDB Throttles | > 10 in 5 min | SNS notification |
| SES Bounce Rate | > 5% | SNS notification |

### X-Ray Tracing

**Trace Flow**:
```
API Gateway → Lambda → DynamoDB
                    → S3
                    → Textract
```

**Benefits**:
- Identify bottlenecks
- Debug errors
- Visualize request flow
- Measure service latency

---

## 🚀 Deployment Options

### Option 1: Terraform (Recommended)
- **Pros**: Infrastructure as Code, version control, reproducible
- **Cons**: Learning curve, requires Terraform knowledge
- **Time**: 10-15 minutes (after code is ready)

### Option 2: AWS Console (Manual)
- **Pros**: Visual, no coding, good for learning
- **Cons**: Time-consuming, error-prone, not reproducible
- **Time**: 2-3 hours

### Option 3: AWS CDK
- **Pros**: Type-safe, reusable constructs, familiar language (TypeScript)
- **Cons**: Requires CDK knowledge, generates CloudFormation
- **Time**: 15-20 minutes (after code is ready)

---

## 📚 Technology Choices & Reasoning

### Why Serverless?
- **No server management**: Focus on code, not infrastructure
- **Auto-scaling**: Handle traffic spikes automatically
- **Cost-effective**: Pay only for actual usage
- **High availability**: Built-in redundancy

### Why Node.js 18.x for Lambda?
- **Performance**: Faster cold starts than Python
- **Ecosystem**: Rich npm ecosystem
- **Type safety**: TypeScript support
- **Async/await**: Native promise support

### Why DynamoDB over RDS?
- **Serverless**: No server to manage
- **Scalability**: Unlimited scale with on-demand
- **Performance**: Single-digit millisecond latency
- **Cost**: Pay per request, no idle capacity

### Why API Gateway REST over HTTP API?
- **Features**: Full feature set (authorizers, usage plans, caching)
- **Maturity**: More stable, better documentation
- **Integration**: Native Cognito authorizer

### Why EventBridge over CloudWatch Events?
- **Modern**: EventBridge is the evolution of CloudWatch Events
- **Features**: Better filtering, schema registry
- **Integration**: Third-party SaaS integrations

---

## 🎯 Best Practices Implemented

### AWS Well-Architected Framework

**Operational Excellence**:
- ✅ Infrastructure as Code (Terraform)
- ✅ Comprehensive logging (CloudWatch)
- ✅ Automated deployments

**Security**:
- ✅ Encryption at rest and in transit
- ✅ Least privilege IAM
- ✅ Private resources (S3, DynamoDB)
- ✅ JWT authentication

**Reliability**:
- ✅ Auto-scaling serverless components
- ✅ DynamoDB point-in-time recovery
- ✅ Retry logic with exponential backoff
- ✅ Dead letter queues for failed events

**Performance Efficiency**:
- ✅ Right-sized Lambda memory
- ✅ DynamoDB single table design
- ✅ Pre-signed URLs for S3
- ✅ X-Ray tracing

**Cost Optimization**:
- ✅ On-demand billing
- ✅ S3 lifecycle policies
- ✅ Appropriate log retention
- ✅ No idle resources

---

## 🔮 Future Enhancements

### Phase 2 Features
1. **SageMaker Integration**: Replace simple forecasting with DeepAR
2. **Anomaly Detection**: Detect unusual spending patterns
3. **Multi-currency Support**: Handle multiple currencies
4. **Batch Operations**: Bulk cheque import/export
5. **Advanced Reporting**: Custom report templates

### Scalability Improvements
1. **DynamoDB GSIs**: Add indexes for complex queries
2. **Lambda Provisioned Concurrency**: Eliminate cold starts
3. **API Gateway Caching**: Reduce Lambda invocations
4. **CloudFront CDN**: Global content delivery

### Security Enhancements
1. **AWS WAF**: Protect API from attacks
2. **Secrets Manager**: Rotate credentials automatically
3. **GuardDuty**: Threat detection
4. **AWS Config**: Compliance monitoring

---

## 📞 Support & Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/
- **DynamoDB Best Practices**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html
- **Lambda Best Practices**: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html

---

## 📄 License

This architecture documentation is part of the Cheque Management System project.

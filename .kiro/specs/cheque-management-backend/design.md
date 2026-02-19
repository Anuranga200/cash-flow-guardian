# Design Document: Supplier Cheque Management & Cash Flow ML System

## Overview

This document describes the technical design for a serverless, event-driven backend system built on AWS infrastructure. The system manages supplier cheques, tracks bank account balances, automates payment reminders, processes cheque images with OCR, and provides ML-based cash flow forecasting.

### Architecture Principles

- **Serverless-First**: Leverage AWS managed services to minimize operational overhead
- **Event-Driven**: Use EventBridge and S3 events to trigger asynchronous workflows
- **Single Table Design**: Use DynamoDB single table pattern for cost efficiency and performance
- **Security by Design**: Implement authentication, authorization, encryption, and least privilege access
- **Observability**: Comprehensive logging, monitoring, and tracing across all components
- **Cost Optimization**: Pay-per-use pricing model with appropriate service tier selection

### Technology Stack

- **Authentication**: Amazon Cognito User Pools
- **API Layer**: Amazon API Gateway (REST API) with Lambda proxy integration
- **Compute**: AWS Lambda (Node.js 18.x runtime recommended)
- **Database**: Amazon DynamoDB with single table design
- **Storage**: Amazon S3 with server-side encryption
- **OCR**: Amazon Textract
- **ML**: Amazon SageMaker (DeepAR or Forecast service)
- **Notifications**: Amazon SNS + Amazon SES
- **Scheduling**: Amazon EventBridge
- **Monitoring**: Amazon CloudWatch + AWS X-Ray
- **IaC**: AWS CDK (TypeScript) or Terraform

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Frontend Application                        │
│                     (React/Vue/Angular + TypeScript)                 │
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
```

### Data Flow Patterns

**1. Cheque Creation Flow**
```
User → API Gateway → Cheque Lambda → DynamoDB
                                   → Return chequeId
```

**2. Image Upload & OCR Flow**
```
User → API Gateway → Cheque Lambda → Generate Pre-Signed URL
User → S3 Upload (Pre-Signed URL)
S3 Event → Textract Lambda → Textract Service → Update DynamoDB
```

**3. Cheque Clearance Flow**
```
User → API Gateway → Cheque Lambda → Update Status to "cleared"
                                   → Deduct from Bank Balance
                                   → Create Transaction Record
                                   → Return success
```

**4. Daily Reminder Flow**
```
EventBridge (Daily) → Reminder Lambda → Query DynamoDB (upcoming cheques)
                                      → Create Notification Records
                                      → Publish to SNS
                                      → SNS → SES → Email
```

**5. Weekly ML Forecast Flow**
```
EventBridge (Weekly) → ML Lambda → Query DynamoDB (historical cheques)
                                 → Prepare time-series data
                                 → Submit SageMaker Job
                                 → Store forecast in DynamoDB
```

## Components and Interfaces

### 1. Authentication Component (Amazon Cognito)

**Configuration**:
- User Pool Name: `cheque-management-user-pool`
- Password Policy: Minimum 8 characters, require uppercase, lowercase, numbers, symbols
- MFA: Optional (TOTP)
- Email Verification: Required
- Custom Attributes: None initially
- App Client: Web application with JWT token generation

**JWT Token Structure**:
```json
{
  "sub": "user-uuid",
  "cognito:username": "user@example.com",
  "email": "user@example.com",
  "exp": 1234567890,
  "iat": 1234567890
}
```

**Integration**:
- API Gateway uses Cognito User Pool as authorizer
- Lambda functions receive userId from `event.requestContext.authorizer.claims.sub`

### 2. API Gateway Component

**Base URL**: `https://api.example.com/v1`

**Endpoints**:


**Cheques Domain**:
- `POST /cheques` - Create new cheque
- `GET /cheques` - List all cheques for user (with optional filters)
- `GET /cheques/{chequeId}` - Get cheque details
- `PUT /cheques/{chequeId}` - Update cheque
- `DELETE /cheques/{chequeId}` - Soft delete cheque
- `POST /cheques/{chequeId}/upload-url` - Generate pre-signed URL for image upload
- `PUT /cheques/{chequeId}/status` - Update cheque status

**Suppliers Domain**:
- `POST /suppliers` - Create new supplier
- `GET /suppliers` - List all suppliers for user
- `GET /suppliers/{supplierId}` - Get supplier details
- `PUT /suppliers/{supplierId}` - Update supplier
- `DELETE /suppliers/{supplierId}` - Delete supplier (with validation)

**Bank Accounts Domain**:
- `POST /bank-accounts` - Create new bank account
- `GET /bank-accounts` - List all bank accounts for user
- `GET /bank-accounts/{accountId}` - Get account details
- `PUT /bank-accounts/{accountId}` - Update account details
- `DELETE /bank-accounts/{accountId}` - Delete account (with validation)
- `GET /bank-accounts/{accountId}/transactions` - Get transaction history

**Notifications Domain**:
- `GET /notifications` - List notifications for user
- `PUT /notifications/{notificationId}/read` - Mark notification as read
- `DELETE /notifications/{notificationId}` - Delete notification

**Reports Domain**:
- `POST /reports/export` - Generate Excel report and return download URL

**Forecasts Domain**:
- `GET /forecasts` - Get latest ML forecast data
- `GET /forecasts/{dateRange}` - Get forecast for specific date range

**Authorization**:
- All endpoints require valid JWT token in Authorization header
- Format: `Authorization: Bearer <jwt-token>`

**Error Response Format**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid cheque status transition",
    "details": {}
  }
}
```

### 3. Lambda Functions

**3.1 Cheque Management Lambda**

**Handler**: `cheques.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name
- `S3_BUCKET_NAME`: Cheque images bucket name
- `PRESIGNED_URL_EXPIRY`: 900 (15 minutes)

**Operations**:
- Create cheque: Validate supplier and bank account exist, generate unique ID, store in DynamoDB
- List cheques: Query by PK=USER#{userId}, SK begins_with CHEQUE#
- Get cheque: Query by PK and SK
- Update cheque: Validate changes, update record
- Delete cheque: Set deleted flag
- Generate upload URL: Create pre-signed S3 PUT URL
- Update status: Validate transition, if cleared → trigger balance update

**IAM Permissions**:
- DynamoDB: GetItem, PutItem, UpdateItem, Query
- S3: PutObject (for pre-signed URL generation)

**3.2 Supplier Management Lambda**

**Handler**: `suppliers.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name

**Operations**:
- Create supplier: Validate email format, generate unique ID, store in DynamoDB
- List suppliers: Query by PK=USER#{userId}, SK begins_with SUPPLIER#
- Get supplier: Query by PK and SK
- Update supplier: Validate changes, update record
- Delete supplier: Check for associated cheques, prevent if exists

**IAM Permissions**:
- DynamoDB: GetItem, PutItem, UpdateItem, Query

**3.3 Bank Account Management Lambda**

**Handler**: `bank-accounts.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name

**Operations**:
- Create account: Initialize balance, store in DynamoDB
- List accounts: Query by PK=USER#{userId}, SK begins_with BANK#
- Get account: Query by PK and SK
- Update account: Update details, preserve balance unless explicitly changed
- Delete account: Check for associated cheques, prevent if exists
- Get transactions: Query transaction records for account
- Update balance: Atomic update with transaction record creation

**IAM Permissions**:
- DynamoDB: GetItem, PutItem, UpdateItem, Query

**3.4 Notification Management Lambda**

**Handler**: `notifications.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name

**Operations**:
- List notifications: Query by PK=USER#{userId}, SK begins_with NOTIF#, sort by date
- Mark as read: Update read flag
- Delete notification: Remove record

**IAM Permissions**:
- DynamoDB: GetItem, UpdateItem, DeleteItem, Query

**3.5 Report Generation Lambda**

**Handler**: `reports.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name
- `S3_BUCKET_NAME`: Reports bucket name
- `PRESIGNED_URL_EXPIRY`: 3600 (1 hour)

**Operations**:
- Export cheques: Query cheques with filters, generate Excel using library (e.g., ExcelJS), upload to S3, return pre-signed download URL

**IAM Permissions**:
- DynamoDB: Query
- S3: PutObject, GetObject (for pre-signed URL)

**3.6 Forecast Management Lambda**

**Handler**: `forecasts.handler`

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name

**Operations**:
- Get forecasts: Query by PK=USER#{userId}, SK begins_with FORECAST#
- Get specific forecast: Query by PK and SK with date range

**IAM Permissions**:
- DynamoDB: Query

**3.7 Textract OCR Lambda**

**Handler**: `textract-processor.handler`

**Trigger**: S3 Event (ObjectCreated)

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name

**Operations**:
- Receive S3 event with bucket and key
- Extract userId and chequeId from S3 key path
- Invoke Textract DetectDocumentText API
- Parse response for cheque number, amount, date, payee
- Update cheque record in DynamoDB with extracted data

**IAM Permissions**:
- S3: GetObject
- Textract: DetectDocumentText
- DynamoDB: UpdateItem

**Error Handling**: Log errors, do not fail if extraction incomplete

**3.8 Reminder Scheduler Lambda**

**Handler**: `reminder-scheduler.handler`

**Trigger**: EventBridge rule (cron: daily at 9 AM UTC)

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name
- `SNS_TOPIC_ARN`: Topic for email notifications

**Operations**:
- Calculate target dates: today + 5 days, today + 1 day
- Query cheques with chequeDate matching target dates and status != cleared
- For each cheque: Create notification record, publish to SNS with email details
- Log summary of notifications sent

**IAM Permissions**:
- DynamoDB: Query, PutItem
- SNS: Publish

**3.9 ML Forecast Lambda**

**Handler**: `ml-forecast.handler`

**Trigger**: EventBridge rule (cron: weekly on Sunday at 2 AM UTC)

**Environment Variables**:
- `TABLE_NAME`: DynamoDB table name
- `SAGEMAKER_ENDPOINT`: SageMaker endpoint name (or use Forecast service)

**Operations**:
- Query all cleared cheques for user (historical data)
- Aggregate by date to create time-series: {date: amount}
- Prepare input format for SageMaker/Forecast
- Submit batch prediction job or invoke endpoint
- Parse forecast results
- Store in DynamoDB with SK=FORECAST#{startDate}-{endDate}

**IAM Permissions**:
- DynamoDB: Query, PutItem
- SageMaker: InvokeEndpoint (or Forecast API permissions)

**Phase 1**: Basic forecasting with simple aggregation
**Phase 2**: Integrate SageMaker DeepAR or Forecast service

### 4. DynamoDB Single Table Design

**Table Name**: `FinanceSystemTable`

**Primary Key**:
- Partition Key (PK): String
- Sort Key (SK): String

**Attributes**: Flexible schema, attributes vary by entity type

**Entity Patterns**:


**User Profile**:
```
PK: USER#<userId>
SK: PROFILE
Attributes: email, name, createdAt
```

**Supplier**:
```
PK: USER#<userId>
SK: SUPPLIER#<supplierId>
Attributes: company, contactPerson, phone, email, paymentTermsDays, createdAt
```

**Bank Account**:
```
PK: USER#<userId>
SK: BANK#<accountId>
Attributes: bankName, accountName, currentBalance, lastUpdated, createdAt
```

**Cheque**:
```
PK: USER#<userId>
SK: CHEQUE#<chequeId>
Attributes: supplierId, chequeNumber, amount, chequeDate, bankAccountId, status, imageUrl, notes, createdAt, deleted
```

**Notification**:
```
PK: USER#<userId>
SK: NOTIF#<timestamp>
Attributes: message, chequeId, dateSent, type, read
```

**Forecast**:
```
PK: USER#<userId>
SK: FORECAST#<dateRange>
Attributes: predictions (array of {date, predictedOutflow, actualOutflow}), generatedAt
```

**Transaction Record**:
```
PK: USER#<userId>
SK: TRANSACTION#<accountId>#<timestamp>
Attributes: chequeId, amount, previousBalance, newBalance, timestamp, type
```

**Access Patterns**:

1. Get user profile: Query PK=USER#{userId}, SK=PROFILE
2. List suppliers for user: Query PK=USER#{userId}, SK begins_with SUPPLIER#
3. Get specific supplier: Query PK=USER#{userId}, SK=SUPPLIER#{supplierId}
4. List bank accounts: Query PK=USER#{userId}, SK begins_with BANK#
5. List cheques: Query PK=USER#{userId}, SK begins_with CHEQUE#
6. Get cheques by status: Query + filter on status attribute
7. Get cheques by date range: Query + filter on chequeDate
8. List notifications: Query PK=USER#{userId}, SK begins_with NOTIF#, sort descending
9. Get transactions for account: Query PK=USER#{userId}, SK begins_with TRANSACTION#{accountId}#
10. Get forecasts: Query PK=USER#{userId}, SK begins_with FORECAST#

**Global Secondary Indexes (GSI)**:

**GSI1 - Cheque Status Index** (Optional, for efficient status queries):
- PK: GSI1PK = USER#{userId}#STATUS#{status}
- SK: GSI1SK = CHEQUE#{chequeDate}
- Use case: Query all cheques by status for a user, sorted by date

**GSI2 - Cheque Date Index** (Optional, for reminder queries):
- PK: GSI2PK = CHEQUE_DATE#{date}
- SK: GSI2SK = USER#{userId}#CHEQUE#{chequeId}
- Use case: Query all cheques across users for a specific date (for reminder system)

**Note**: Start without GSIs, add only if query performance requires optimization.

**Table Configuration**:
- Billing Mode: On-Demand (pay per request)
- Encryption: AWS managed key (SSE)
- Point-in-Time Recovery: Enabled
- Stream: Disabled initially (can enable for audit trail)

### 5. S3 Storage Component

**Bucket Name**: `cheque-management-images-{accountId}`

**Configuration**:
- Block Public Access: Enabled (all settings)
- Versioning: Disabled
- Encryption: SSE-S3 (AES-256)
- Lifecycle Policy: Transition to Glacier after 365 days
- CORS: Enabled for pre-signed URL uploads

**Object Key Structure**:
```
{userId}/cheques/{chequeId}.jpg
{userId}/reports/{reportId}.xlsx
```

**Event Notifications**:
- Event: s3:ObjectCreated:*
- Prefix: */cheques/*
- Destination: Textract Lambda function

**Pre-Signed URL Generation**:
- Expiry: 15 minutes for uploads
- Expiry: 1 hour for downloads
- HTTP Method: PUT for uploads, GET for downloads

### 6. Amazon Textract Integration

**API Used**: `DetectDocumentText`

**Input**: S3 object reference (bucket + key)

**Output**: JSON with detected text blocks

**Extraction Logic**:
- Cheque Number: Pattern matching for numeric sequences (6-10 digits)
- Amount: Pattern matching for currency format ($X,XXX.XX or XXXX.XX)
- Date: Pattern matching for date formats (MM/DD/YYYY, DD-MM-YYYY)
- Payee: Extract text from "Pay to the order of" line

**Error Handling**:
- If Textract fails: Log error, continue without updating cheque
- If parsing fails: Store raw text, mark as needs manual review
- Retry logic: 3 attempts with exponential backoff

### 7. EventBridge Scheduling

**Rule 1: Daily Reminder**
- Name: `cheque-reminder-daily`
- Schedule: `cron(0 9 * * ? *)` (9 AM UTC daily)
- Target: Reminder Lambda function
- Enabled: True

**Rule 2: Weekly ML Forecast**
- Name: `ml-forecast-weekly`
- Schedule: `cron(0 2 ? * SUN *)` (2 AM UTC every Sunday)
- Target: ML Forecast Lambda function
- Enabled: True

### 8. SNS and SES Integration

**SNS Topic**:
- Name: `cheque-reminders`
- Subscription: Email protocol → SES
- Message Format: JSON with cheque details

**SES Configuration**:
- Verified Sender: `noreply@example.com`
- Email Template: HTML template with cheque details
- Bounce Handling: SNS topic for bounces
- Complaint Handling: SNS topic for complaints

**Email Template Structure**:
```
Subject: Payment Reminder - Cheque Due {date}

Body:
Dear User,

This is a reminder that the following cheque is due for clearance:

Supplier: {supplierName}
Cheque Number: {chequeNumber}
Amount: ${amount}
Due Date: {chequeDate}
Bank Account: {bankName}

Please ensure sufficient funds are available.

Best regards,
Cheque Management System
```

### 9. SageMaker ML Pipeline

**Phase 1: Basic Forecasting**
- Aggregate historical cheque data by week
- Calculate average weekly outflow
- Simple linear projection for next 4 weeks
- Store in DynamoDB

**Phase 2: SageMaker Integration**

**Model**: DeepAR (time-series forecasting)

**Training Data Format**:
```json
{
  "start": "2024-01-01",
  "target": [1000, 1500, 2000, 1200, ...],
  "cat": [0],
  "dynamic_feat": []
}
```

**Inference**:
- Input: Historical time-series data
- Output: Predicted values for next N periods with confidence intervals

**Deployment**:
- Option A: Real-time endpoint (higher cost, immediate results)
- Option B: Batch transform job (lower cost, scheduled execution)

**Recommendation**: Start with batch transform for weekly forecasts

**SageMaker Execution Role**:
- S3 access for training data and model artifacts
- CloudWatch Logs for monitoring

## Data Models

### TypeScript Interfaces (Backend Internal)

**Cheque Entity**:
```typescript
interface ChequeEntity {
  PK: string;              // USER#<userId>
  SK: string;              // CHEQUE#<chequeId>
  id: string;              // chequeId
  userId: string;
  supplierId: string;
  chequeNumber: string;
  amount: number;
  chequeDate: string;      // ISO 8601 format
  bankAccountId: string;
  status: 'issued' | 'upcoming' | 'cleared' | 'bounced' | 'cancelled';
  imageUrl?: string;
  notes?: string;
  createdAt: string;
  deleted?: boolean;
  extractedData?: {
    chequeNumber?: string;
    amount?: number;
    date?: string;
    payee?: string;
    confidence?: number;
  };
}
```

**Supplier Entity**:
```typescript
interface SupplierEntity {
  PK: string;              // USER#<userId>
  SK: string;              // SUPPLIER#<supplierId>
  id: string;              // supplierId
  userId: string;
  company: string;
  contactPerson: string;
  phone: string;
  email: string;
  paymentTermsDays: number;
  createdAt: string;
}
```

**Bank Account Entity**:
```typescript
interface BankAccountEntity {
  PK: string;              // USER#<userId>
  SK: string;              // BANK#<accountId>
  id: string;              // accountId
  userId: string;
  bankName: string;
  accountName: string;
  currentBalance: number;
  lastUpdated: string;
  createdAt: string;
}
```

**Transaction Entity**:
```typescript
interface TransactionEntity {
  PK: string;              // USER#<userId>
  SK: string;              // TRANSACTION#<accountId>#<timestamp>
  userId: string;
  accountId: string;
  chequeId: string;
  amount: number;
  previousBalance: number;
  newBalance: number;
  timestamp: string;
  type: 'debit' | 'credit' | 'adjustment';
}
```

**Notification Entity**:
```typescript
interface NotificationEntity {
  PK: string;              // USER#<userId>
  SK: string;              // NOTIF#<timestamp>
  id: string;              // notificationId
  userId: string;
  message: string;
  chequeId?: string;
  dateSent: string;
  type: 'in-app' | 'email';
  read: boolean;
}
```

**Forecast Entity**:
```typescript
interface ForecastEntity {
  PK: string;              // USER#<userId>
  SK: string;              // FORECAST#<dateRange>
  userId: string;
  dateRange: string;       // e.g., "2024-01-01_2024-01-31"
  predictions: Array<{
    date: string;
    predictedOutflow: number;
    actualOutflow?: number;
    confidenceInterval?: {
      lower: number;
      upper: number;
    };
  }>;
  generatedAt: string;
  modelVersion?: string;
}
```

### Status Transition Rules

**Valid Transitions**:
```
issued → cleared
issued → bounced
issued → cancelled
upcoming → issued
upcoming → cancelled
bounced → cleared (re-presented)
cancelled → (terminal state)
cleared → (terminal state)
```

**Invalid Transitions**:
- cleared → any other status
- cancelled → any other status
- Any status → upcoming (upcoming is initial state only)

### Balance Update Logic

**Pseudocode**:
```
function updateChequeStatus(chequeId, newStatus, userId):
  cheque = getCheque(chequeId, userId)
  
  if not isValidTransition(cheque.status, newStatus):
    throw ValidationError("Invalid status transition")
  
  if newStatus == 'cleared' and cheque.status != 'cleared':
    bankAccount = getBankAccount(cheque.bankAccountId, userId)
    
    // Atomic transaction
    beginTransaction()
    try:
      previousBalance = bankAccount.currentBalance
      newBalance = previousBalance - cheque.amount
      
      updateBankBalance(cheque.bankAccountId, newBalance)
      
      createTransaction({
        accountId: cheque.bankAccountId,
        chequeId: chequeId,
        amount: -cheque.amount,
        previousBalance: previousBalance,
        newBalance: newBalance,
        type: 'debit'
      })
      
      updateCheque(chequeId, {status: newStatus})
      
      commitTransaction()
    catch error:
      rollbackTransaction()
      throw error
  else:
    updateCheque(chequeId, {status: newStatus})
  
  return success
```

**Note**: DynamoDB doesn't support multi-item transactions natively. Use DynamoDB Transactions API or implement compensating transactions for rollback.


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property Reflection Analysis

After analyzing all acceptance criteria, I identified the following redundancies:
- Multiple criteria test data isolation (1.5, 2.3, 3.4, 8.1) → Consolidated into single property
- Storage pattern tests (2.1, 3.1, 4.1, 8.4, 17.3) → Consolidated into entity storage property
- Balance update and transaction creation (4.3, 4.4, 16.2, 16.3, 17.1) → Consolidated into single atomic property
- Token validation (1.2, 1.3, 11.3) → Consolidated into single property
- Input validation (13.6, 15.7) → Consolidated into single property

### Authentication and Authorization Properties

**Property 1: JWT Token Validation**
*For any* API request with an invalid or expired JWT token, the system should reject the request with 401 Unauthorized status before invoking any Lambda function.
**Validates: Requirements 1.2, 1.3, 11.3**

**Property 2: User ID Extraction and Usage**
*For any* authenticated API request, the system should extract userId from the JWT token and use it in all data operations to ensure proper data scoping.
**Validates: Requirements 1.4, 11.4**

**Property 3: Data Isolation**
*For any* two different users (userA and userB), operations performed by userA should never return, modify, or delete data belonging to userB.
**Validates: Requirements 1.5, 2.3, 3.4, 8.1**

### Cheque Management Properties

**Property 4: Entity Storage Pattern**
*For any* entity created (cheque, supplier, bank account, notification, transaction), the DynamoDB record should have PK=USER#{userId} and SK={ENTITY_TYPE}#{entityId} following the single table design pattern.
**Validates: Requirements 2.1, 3.1, 4.1, 8.4, 17.3**

**Property 5: Referential Integrity**
*For any* cheque creation request with non-existent supplierId or bankAccountId, the system should reject the request with a validation error.
**Validates: Requirements 2.2**

**Property 6: Status Transition Validation**
*For any* cheque status update request, if the transition from current status to new status is invalid (e.g., cleared → upcoming), the system should reject the request with a validation error.
**Validates: Requirements 2.4, 16.4**

**Property 7: Soft Deletion**
*For any* cheque deletion request, the cheque record should remain in DynamoDB with deleted=true rather than being physically removed.
**Validates: Requirements 2.5**

**Property 8: Unique ID Generation**
*For any* set of entities created within the same entity type, all generated IDs should be unique.
**Validates: Requirements 2.6**

**Property 9: Timestamp Recording**
*For any* entity creation, the record should include a createdAt timestamp in ISO 8601 format.
**Validates: Requirements 2.7**

### Supplier Management Properties

**Property 10: Email Format Validation**
*For any* supplier creation or update with an invalid email format, the system should reject the request with a validation error.
**Validates: Requirements 3.2**

**Property 11: Required Field Validation**
*For any* supplier creation with empty phone number, the system should reject the request with a validation error.
**Validates: Requirements 3.3**

**Property 12: ID Preservation on Update**
*For any* supplier update operation, the supplierId should remain unchanged after the update.
**Validates: Requirements 3.5**

**Property 13: Cascade Delete Prevention**
*For any* supplier or bank account with associated active cheques, deletion attempts should fail with an appropriate error message.
**Validates: Requirements 3.6, 4.6**

### Bank Account and Transaction Properties

**Property 14: Balance Initialization**
*For any* bank account creation, the currentBalance should be set to the provided initial value.
**Validates: Requirements 4.2**

**Property 15: Atomic Balance Update with Transaction**
*For any* cheque status change to cleared, the system should atomically: (1) deduct the cheque amount from the bank account balance, (2) create a transaction record with previous and new balance, and (3) update the cheque status. If any step fails, all changes should be rolled back.
**Validates: Requirements 4.3, 4.4, 16.2, 16.3, 17.1**

**Property 16: Balance Update Timestamp**
*For any* bank account balance change, the lastUpdated timestamp should be updated to the current time.
**Validates: Requirements 4.5**

**Property 17: Balance Precision**
*For any* bank account balance calculation, the result should be rounded to exactly two decimal places.
**Validates: Requirements 4.7**

### Image Storage and OCR Properties

**Property 18: Pre-Signed URL Generation**
*For any* cheque image upload request, the system should return a valid pre-signed S3 URL that expires in 15 minutes and allows PUT operations.
**Validates: Requirements 5.1, 10.4**

**Property 19: S3 Path Structure**
*For any* cheque image stored in S3, the object key should follow the pattern userId/cheques/{chequeId}.jpg.
**Validates: Requirements 5.2**

**Property 20: OCR Data Update**
*For any* successful Textract extraction, the cheque record should be updated with extractedData containing the parsed fields.
**Validates: Requirements 5.6**

**Property 21: Image URL Storage**
*For any* cheque with an uploaded image, the cheque record should contain an imageUrl field pointing to the S3 object.
**Validates: Requirements 5.7**

### Reminder System Properties

**Property 22: Upcoming Cheque Query**
*For any* reminder execution on date D, the system should query and return all cheques with chequeDate equal to D+5 days or D+1 day and status not equal to cleared.
**Validates: Requirements 6.2, 6.3**

**Property 23: Notification Creation for Reminders**
*For any* cheque identified by the reminder system, the system should create both an in-app notification record and publish an SNS message.
**Validates: Requirements 6.4, 6.5**

**Property 24: Notification Content Completeness**
*For any* notification created, the message should include supplier name, cheque amount, and cheque date.
**Validates: Requirements 6.6, 7.3**

**Property 25: Notification Initial State**
*For any* newly created notification, the read field should be false and dateSent should be set to the current timestamp.
**Validates: Requirements 6.7**

### Email Notification Properties

**Property 26: Email Message Formatting**
*For any* email notification, the message should have a non-empty subject line and a structured body containing cheque details.
**Validates: Requirements 7.2**

**Property 27: Email Delivery Logging**
*For any* email delivery attempt, the system should create a log entry with timestamp, recipient, and delivery status.
**Validates: Requirements 7.5**

### In-App Notification Properties

**Property 28: Notification Ordering**
*For any* notification list request, the returned notifications should be ordered by dateSent in descending order (newest first).
**Validates: Requirements 8.2**

**Property 29: Mark as Read**
*For any* notification mark-as-read operation, the notification's read field should be updated to true.
**Validates: Requirements 8.3**

**Property 30: Notification Filtering**
*For any* notification list request with read status filter, all returned notifications should match the specified read status.
**Validates: Requirements 8.5**

### ML Forecasting Properties

**Property 31: Historical Data Retrieval**
*For any* ML forecast execution for userId, the system should retrieve only cheque records belonging to that userId with status=cleared.
**Validates: Requirements 9.2**

**Property 32: Time-Series Data Preparation**
*For any* set of historical cheques, the prepared time-series data should be an array of objects with date and outflow amount fields, aggregated by date.
**Validates: Requirements 9.3**

**Property 33: Forecast Storage**
*For any* completed ML forecast, the results should be stored in DynamoDB with PK=USER#{userId} and SK=FORECAST#{dateRange}.
**Validates: Requirements 9.5**

**Property 34: Future Date Predictions**
*For any* stored forecast, the predictions array should contain only dates in the future relative to the forecast generation time.
**Validates: Requirements 9.6**

### Report Generation Properties

**Property 35: Report Filtering**
*For any* report generation request with filter criteria, the resulting Excel file should contain only cheques matching all specified filters.
**Validates: Requirements 10.1**

**Property 36: Report Completeness**
*For any* generated Excel report, all cheque fields (id, supplierId, chequeNumber, amount, chequeDate, bankAccountId, status, notes, createdAt) should be included as columns.
**Validates: Requirements 10.2**

**Property 37: Unique Report Filename**
*For any* two report generation requests, the generated S3 filenames should be unique.
**Validates: Requirements 10.3**

**Property 38: Excel Header Row**
*For any* generated Excel file, the first row should contain column headers for all cheque fields.
**Validates: Requirements 10.6**

**Property 39: Excel Data Formatting**
*For any* generated Excel file, date fields should be formatted as YYYY-MM-DD and currency fields should be formatted with two decimal places and currency symbol.
**Validates: Requirements 10.7**

### API Response Properties

**Property 40: HTTP Status Code Mapping**
*For any* API operation, the HTTP status code should correctly reflect the operation result: 200/201 for success, 400 for validation errors, 401 for authentication failures, 403 for authorization failures, 404 for not found, 500 for server errors.
**Validates: Requirements 11.5**

### Concurrency and Consistency Properties

**Property 41: Optimistic Locking**
*For any* concurrent update scenario where two requests attempt to modify the same entity simultaneously, the system should detect the conflict and reject the second update with a conflict error.
**Validates: Requirements 12.6**

### Security Properties

**Property 42: Input Validation**
*For any* API request with malicious input (SQL injection, XSS, command injection patterns), the system should reject the request with a validation error before processing.
**Validates: Requirements 13.6, 15.7**

**Property 43: Error Message Sanitization**
*For any* error response, the error message should not contain sensitive information such as database connection strings, internal paths, or user data from other users.
**Validates: Requirements 13.7**

### Error Handling Properties

**Property 44: Error Logging**
*For any* Lambda function error or exception, the system should log detailed error information including timestamp, function name, error type, and stack trace to CloudWatch.
**Validates: Requirements 15.1**

**Property 45: Idempotency**
*For any* critical operation (cheque creation, status update, balance update) with an idempotency key, multiple requests with the same key should produce the same result and side effects should occur only once.
**Validates: Requirements 15.4**

**Property 46: Error Code Appropriateness**
*For any* external service failure (Textract, SageMaker, S3), the system should return an appropriate error code to the client (503 Service Unavailable or 500 Internal Server Error) rather than exposing internal error details.
**Validates: Requirements 15.5**

### Status Workflow Properties

**Property 47: Bounced Cheque Notification**
*For any* cheque status change to bounced, the system should create a notification alerting the user.
**Validates: Requirements 16.5**

**Property 48: Cancelled Cheque Balance Preservation**
*For any* cheque status change to cancelled, the associated bank account balance should remain unchanged.
**Validates: Requirements 16.6**

**Property 49: Status Change Audit**
*For any* cheque status change, the system should record the timestamp and userId who performed the change.
**Validates: Requirements 16.7**

### Transaction Audit Properties

**Property 50: Transaction Record Completeness**
*For any* transaction record, it should include all required fields: timestamp, userId, chequeId, amount, previousBalance, newBalance, and type.
**Validates: Requirements 17.2**

**Property 51: Transaction Immutability**
*For any* transaction record created, it should never be modified or deleted after creation.
**Validates: Requirements 17.4, 17.6**

**Property 52: Transaction Chronological Ordering**
*For any* transaction history query, the returned records should be ordered by timestamp in ascending order (oldest first).
**Validates: Requirements 17.5**

**Property 53: Transaction Amount Consistency**
*For any* transaction record created from a cheque clearance, the transaction amount should exactly match the cheque amount (with opposite sign for debit).
**Validates: Requirements 17.7**


## Error Handling

### Error Categories

**1. Validation Errors (400 Bad Request)**
- Invalid email format
- Empty required fields
- Invalid status transitions
- Invalid date formats
- Negative amounts
- Malformed JSON

**2. Authentication Errors (401 Unauthorized)**
- Missing JWT token
- Expired JWT token
- Invalid JWT signature
- Malformed JWT token

**3. Authorization Errors (403 Forbidden)**
- Attempting to access another user's data
- Insufficient permissions

**4. Not Found Errors (404 Not Found)**
- Cheque ID not found
- Supplier ID not found
- Bank account ID not found
- Notification ID not found

**5. Conflict Errors (409 Conflict)**
- Optimistic locking conflict
- Duplicate cheque number
- Attempting to delete supplier with active cheques

**6. Service Errors (500 Internal Server Error)**
- DynamoDB operation failures
- Unexpected exceptions
- Data corruption

**7. Service Unavailable Errors (503 Service Unavailable)**
- Textract service failure
- SageMaker service failure
- S3 service failure
- SNS/SES service failure

### Error Response Format

All API errors follow a consistent JSON structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "fieldName",
      "reason": "Specific reason for failure"
    },
    "requestId": "uuid-for-tracing"
  }
}
```

### Error Codes

```typescript
enum ErrorCode {
  // Validation
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INVALID_EMAIL = 'INVALID_EMAIL',
  INVALID_STATUS_TRANSITION = 'INVALID_STATUS_TRANSITION',
  REQUIRED_FIELD_MISSING = 'REQUIRED_FIELD_MISSING',
  
  // Authentication/Authorization
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  INVALID_TOKEN = 'INVALID_TOKEN',
  EXPIRED_TOKEN = 'EXPIRED_TOKEN',
  
  // Not Found
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  CHEQUE_NOT_FOUND = 'CHEQUE_NOT_FOUND',
  SUPPLIER_NOT_FOUND = 'SUPPLIER_NOT_FOUND',
  BANK_ACCOUNT_NOT_FOUND = 'BANK_ACCOUNT_NOT_FOUND',
  
  // Conflict
  CONFLICT = 'CONFLICT',
  OPTIMISTIC_LOCK_FAILURE = 'OPTIMISTIC_LOCK_FAILURE',
  CASCADE_DELETE_PREVENTED = 'CASCADE_DELETE_PREVENTED',
  
  // Service Errors
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  DATABASE_ERROR = 'DATABASE_ERROR',
  SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
  TEXTRACT_ERROR = 'TEXTRACT_ERROR',
  SAGEMAKER_ERROR = 'SAGEMAKER_ERROR'
}
```

### Retry Logic

**Exponential Backoff Configuration**:
```typescript
const retryConfig = {
  maxRetries: 3,
  baseDelay: 100,  // milliseconds
  maxDelay: 5000,  // milliseconds
  factor: 2
};

function calculateDelay(attempt: number): number {
  return Math.min(
    retryConfig.baseDelay * Math.pow(retryConfig.factor, attempt),
    retryConfig.maxDelay
  );
}
```

**Retryable Operations**:
- DynamoDB throttling errors (ProvisionedThroughputExceededException)
- Textract throttling errors
- SageMaker throttling errors
- Network timeouts
- 503 Service Unavailable responses

**Non-Retryable Operations**:
- Validation errors (400)
- Authentication errors (401)
- Authorization errors (403)
- Not found errors (404)
- Conflict errors (409)

### Idempotency Implementation

**Idempotency Key Header**: `Idempotency-Key: <uuid>`

**Critical Operations Requiring Idempotency**:
- Cheque creation
- Cheque status updates (especially to cleared)
- Bank account balance updates
- Transaction record creation

**Implementation**:
```typescript
interface IdempotencyRecord {
  PK: string;  // IDEMPOTENCY#<idempotencyKey>
  SK: string;  // METADATA
  requestHash: string;
  response: any;
  statusCode: number;
  expiresAt: number;  // TTL
}

async function handleIdempotentRequest(
  idempotencyKey: string,
  request: any,
  handler: () => Promise<any>
): Promise<any> {
  // Check if request already processed
  const existing = await getIdempotencyRecord(idempotencyKey);
  
  if (existing && existing.requestHash === hash(request)) {
    // Return cached response
    return existing.response;
  }
  
  // Process request
  const response = await handler();
  
  // Store idempotency record (24 hour TTL)
  await storeIdempotencyRecord({
    idempotencyKey,
    requestHash: hash(request),
    response,
    expiresAt: Date.now() + 86400000
  });
  
  return response;
}
```

### Dead Letter Queues

**DLQ Configuration**:
- All asynchronous Lambda functions have DLQ configured
- Failed events sent to SQS DLQ after max retry attempts
- CloudWatch alarm triggers on DLQ message count > 0
- Manual review and reprocessing required

**Functions with DLQ**:
- Textract OCR Lambda
- Reminder Scheduler Lambda
- ML Forecast Lambda

### Circuit Breaker Pattern

For external service calls (Textract, SageMaker), implement circuit breaker:

```typescript
enum CircuitState {
  CLOSED,   // Normal operation
  OPEN,     // Failing, reject requests
  HALF_OPEN // Testing if service recovered
}

class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private lastFailureTime: number = 0;
  
  private readonly threshold = 5;
  private readonly timeout = 60000; // 1 minute
  
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastFailureTime > this.timeout) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  private onSuccess(): void {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }
  
  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    
    if (this.failureCount >= this.threshold) {
      this.state = CircuitState.OPEN;
    }
  }
}
```

## Testing Strategy

### Dual Testing Approach

The system requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**: Focus on specific examples, edge cases, and integration points
**Property Tests**: Verify universal properties across all inputs through randomization

Both approaches are complementary and necessary. Unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across a wide input space.

### Property-Based Testing Configuration

**Library Selection**: 
- **Node.js/TypeScript**: fast-check
- **Python**: Hypothesis

**Configuration**:
```typescript
import fc from 'fast-check';

// Minimum 100 iterations per property test
fc.configureGlobal({
  numRuns: 100,
  verbose: true
});
```

**Test Tagging**:
Each property test must include a comment referencing the design document property:

```typescript
// Feature: cheque-management-backend, Property 3: Data Isolation
test('user data isolation property', async () => {
  await fc.assert(
    fc.asyncProperty(
      fc.record({
        userA: userArbitrary(),
        userB: userArbitrary(),
        cheque: chequeArbitrary()
      }),
      async ({ userA, userB, cheque }) => {
        // Test implementation
      }
    )
  );
});
```

### Test Organization

**Directory Structure**:
```
tests/
├── unit/
│   ├── cheques/
│   │   ├── create-cheque.test.ts
│   │   ├── update-status.test.ts
│   │   └── delete-cheque.test.ts
│   ├── suppliers/
│   ├── bank-accounts/
│   ├── notifications/
│   ├── reports/
│   └── forecasts/
├── property/
│   ├── authentication.property.test.ts
│   ├── data-isolation.property.test.ts
│   ├── cheque-management.property.test.ts
│   ├── bank-transactions.property.test.ts
│   └── audit-trail.property.test.ts
├── integration/
│   ├── cheque-clearance-flow.test.ts
│   ├── reminder-workflow.test.ts
│   └── ml-forecast-workflow.test.ts
└── e2e/
    └── api-endpoints.test.ts
```

### Unit Test Coverage

**Focus Areas**:
1. **Specific Examples**: Test concrete scenarios with known inputs/outputs
2. **Edge Cases**: Empty strings, null values, boundary values, maximum lengths
3. **Error Conditions**: Invalid inputs, missing required fields, constraint violations
4. **Integration Points**: Lambda-DynamoDB, Lambda-S3, Lambda-Textract interactions

**Example Unit Tests**:
```typescript
describe('Cheque Creation', () => {
  test('should create cheque with valid data', async () => {
    const cheque = {
      supplierId: 'supplier-123',
      chequeNumber: 'CHQ001',
      amount: 1000.50,
      chequeDate: '2024-06-01',
      bankAccountId: 'bank-456'
    };
    
    const result = await createCheque(userId, cheque);
    
    expect(result.id).toBeDefined();
    expect(result.amount).toBe(1000.50);
  });
  
  test('should reject cheque with non-existent supplier', async () => {
    const cheque = {
      supplierId: 'non-existent',
      chequeNumber: 'CHQ001',
      amount: 1000.50,
      chequeDate: '2024-06-01',
      bankAccountId: 'bank-456'
    };
    
    await expect(createCheque(userId, cheque))
      .rejects
      .toThrow('SUPPLIER_NOT_FOUND');
  });
  
  test('should reject cheque with negative amount', async () => {
    const cheque = {
      supplierId: 'supplier-123',
      chequeNumber: 'CHQ001',
      amount: -100,
      chequeDate: '2024-06-01',
      bankAccountId: 'bank-456'
    };
    
    await expect(createCheque(userId, cheque))
      .rejects
      .toThrow('VALIDATION_ERROR');
  });
});
```

### Property-Based Test Examples

**Property 3: Data Isolation**
```typescript
// Feature: cheque-management-backend, Property 3: Data Isolation
test('user data isolation property', async () => {
  await fc.assert(
    fc.asyncProperty(
      fc.record({
        userA: fc.uuid(),
        userB: fc.uuid().filter(id => id !== userA),
        cheque: fc.record({
          supplierId: fc.uuid(),
          chequeNumber: fc.string({ minLength: 1, maxLength: 20 }),
          amount: fc.double({ min: 0.01, max: 1000000 }),
          chequeDate: fc.date(),
          bankAccountId: fc.uuid()
        })
      }),
      async ({ userA, userB, cheque }) => {
        // Create cheque for userA
        await createCheque(userA, cheque);
        
        // Attempt to retrieve as userB
        const result = await listCheques(userB);
        
        // UserB should not see userA's cheque
        expect(result.items).not.toContainEqual(
          expect.objectContaining({ chequeNumber: cheque.chequeNumber })
        );
      }
    ),
    { numRuns: 100 }
  );
});
```

**Property 15: Atomic Balance Update with Transaction**
```typescript
// Feature: cheque-management-backend, Property 15: Atomic Balance Update with Transaction
test('atomic balance update property', async () => {
  await fc.assert(
    fc.asyncProperty(
      fc.record({
        userId: fc.uuid(),
        initialBalance: fc.double({ min: 1000, max: 100000 }),
        chequeAmount: fc.double({ min: 0.01, max: 1000 })
      }),
      async ({ userId, initialBalance, chequeAmount }) => {
        // Setup: Create bank account and cheque
        const bankAccount = await createBankAccount(userId, {
          bankName: 'Test Bank',
          accountName: 'Test Account',
          currentBalance: initialBalance
        });
        
        const supplier = await createSupplier(userId, {
          company: 'Test Supplier',
          email: 'test@example.com',
          phone: '1234567890',
          contactPerson: 'John Doe',
          paymentTermsDays: 30
        });
        
        const cheque = await createCheque(userId, {
          supplierId: supplier.id,
          chequeNumber: 'CHQ' + Date.now(),
          amount: chequeAmount,
          chequeDate: new Date().toISOString(),
          bankAccountId: bankAccount.id,
          status: 'issued'
        });
        
        // Action: Clear the cheque
        await updateChequeStatus(userId, cheque.id, 'cleared');
        
        // Verify: Balance updated
        const updatedAccount = await getBankAccount(userId, bankAccount.id);
        expect(updatedAccount.currentBalance).toBeCloseTo(
          initialBalance - chequeAmount,
          2
        );
        
        // Verify: Transaction record created
        const transactions = await getTransactions(userId, bankAccount.id);
        expect(transactions).toContainEqual(
          expect.objectContaining({
            chequeId: cheque.id,
            amount: -chequeAmount,
            previousBalance: initialBalance,
            newBalance: initialBalance - chequeAmount
          })
        );
        
        // Verify: Cheque status updated
        const updatedCheque = await getCheque(userId, cheque.id);
        expect(updatedCheque.status).toBe('cleared');
      }
    ),
    { numRuns: 100 }
  );
});
```

**Property 6: Status Transition Validation**
```typescript
// Feature: cheque-management-backend, Property 6: Status Transition Validation
test('status transition validation property', async () => {
  const invalidTransitions = [
    ['cleared', 'upcoming'],
    ['cleared', 'issued'],
    ['cleared', 'bounced'],
    ['cancelled', 'issued'],
    ['cancelled', 'cleared']
  ];
  
  await fc.assert(
    fc.asyncProperty(
      fc.record({
        userId: fc.uuid(),
        transition: fc.constantFrom(...invalidTransitions)
      }),
      async ({ userId, transition }) => {
        const [fromStatus, toStatus] = transition;
        
        // Create cheque with fromStatus
        const cheque = await createChequeWithStatus(userId, fromStatus);
        
        // Attempt invalid transition
        await expect(
          updateChequeStatus(userId, cheque.id, toStatus)
        ).rejects.toThrow('INVALID_STATUS_TRANSITION');
      }
    ),
    { numRuns: 100 }
  );
});
```

### Integration Testing

**Focus**: Test workflows that span multiple Lambda functions and services

**Example Integration Tests**:
1. **Cheque Clearance Flow**: Create cheque → Upload image → Textract processing → Status update → Balance deduction
2. **Reminder Workflow**: Create upcoming cheques → Trigger reminder Lambda → Verify notifications created → Verify SNS messages published
3. **ML Forecast Workflow**: Create historical cheques → Trigger ML Lambda → Verify forecast stored

### Mocking Strategy

**AWS Service Mocks**:
- Use `aws-sdk-mock` or `@aws-sdk/client-mock` for mocking AWS services
- Mock DynamoDB, S3, Textract, SageMaker, SNS, SES in unit tests
- Use LocalStack for integration tests requiring real AWS service behavior

**Example Mock**:
```typescript
import { mockClient } from 'aws-sdk-client-mock';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const ddbMock = mockClient(DynamoDBDocumentClient);

beforeEach(() => {
  ddbMock.reset();
});

test('should store cheque in DynamoDB', async () => {
  ddbMock.on(PutCommand).resolves({});
  
  await createCheque(userId, chequeData);
  
  expect(ddbMock.calls()).toHaveLength(1);
  expect(ddbMock.call(0).args[0].input).toMatchObject({
    TableName: 'FinanceSystemTable',
    Item: expect.objectContaining({
      PK: `USER#${userId}`,
      SK: expect.stringMatching(/^CHEQUE#/)
    })
  });
});
```

### Test Data Generators (Arbitraries)

**fast-check Arbitraries**:
```typescript
import fc from 'fast-check';

export const userIdArbitrary = () => fc.uuid();

export const chequeStatusArbitrary = () => 
  fc.constantFrom('issued', 'upcoming', 'cleared', 'bounced', 'cancelled');

export const chequeArbitrary = () => fc.record({
  supplierId: fc.uuid(),
  chequeNumber: fc.string({ minLength: 1, maxLength: 20 }),
  amount: fc.double({ min: 0.01, max: 1000000, noNaN: true }),
  chequeDate: fc.date().map(d => d.toISOString()),
  bankAccountId: fc.uuid(),
  status: chequeStatusArbitrary(),
  notes: fc.option(fc.string({ maxLength: 500 }), { nil: undefined })
});

export const supplierArbitrary = () => fc.record({
  company: fc.string({ minLength: 1, maxLength: 100 }),
  contactPerson: fc.string({ minLength: 1, maxLength: 100 }),
  phone: fc.string({ minLength: 10, maxLength: 15 }),
  email: fc.emailAddress(),
  paymentTermsDays: fc.integer({ min: 0, max: 365 })
});

export const bankAccountArbitrary = () => fc.record({
  bankName: fc.string({ minLength: 1, maxLength: 100 }),
  accountName: fc.string({ minLength: 1, maxLength: 100 }),
  currentBalance: fc.double({ min: 0, max: 10000000, noNaN: true })
});
```

### CI/CD Testing Pipeline

**Pipeline Stages**:
1. **Lint**: ESLint, Prettier
2. **Unit Tests**: Run all unit tests with coverage
3. **Property Tests**: Run all property-based tests (100 iterations each)
4. **Integration Tests**: Run integration tests against LocalStack
5. **Coverage Report**: Minimum 80% code coverage required
6. **Deploy to Dev**: If all tests pass

**Coverage Requirements**:
- Overall: 80% minimum
- Critical paths (balance updates, status transitions): 95% minimum
- Lambda handlers: 90% minimum

### Performance Testing

**Load Testing**:
- Use Artillery or k6 for API load testing
- Target: 100 requests/second sustained
- Latency: p95 < 500ms, p99 < 1000ms

**Stress Testing**:
- Test DynamoDB throttling behavior
- Test Lambda concurrency limits
- Test S3 upload throughput

### Security Testing

**OWASP Top 10 Coverage**:
1. Injection: Test SQL injection, NoSQL injection, command injection
2. Broken Authentication: Test JWT validation, token expiry
3. Sensitive Data Exposure: Test error message sanitization
4. XML External Entities: N/A (no XML processing)
5. Broken Access Control: Test data isolation, authorization
6. Security Misconfiguration: Infrastructure tests
7. XSS: Test input sanitization
8. Insecure Deserialization: Test JSON parsing
9. Using Components with Known Vulnerabilities: Dependency scanning
10. Insufficient Logging: Test CloudWatch logging

**Tools**:
- OWASP ZAP for API security scanning
- npm audit / Snyk for dependency vulnerabilities
- AWS Security Hub for infrastructure security


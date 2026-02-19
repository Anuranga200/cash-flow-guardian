# Requirements Document

## Introduction

This document specifies the requirements for a serverless, event-driven backend system that manages supplier cheques, tracks multiple bank account balances, sends automated payment reminders, stores and processes cheque images using OCR, and provides ML-based cash flow forecasting. The system is built on AWS infrastructure using services including Lambda, DynamoDB, S3, Cognito, API Gateway, Textract, SageMaker, EventBridge, SNS, and SES.

The system must support secure multi-user access with data isolation, maintain accurate financial records with audit trails, automate notification workflows, and provide predictive analytics for cash flow management.

## Glossary

- **System**: The Supplier Cheque Management & Cash Flow ML System
- **User**: An authenticated person accessing the system through Cognito
- **Cheque**: A financial instrument with status, amount, date, and associated supplier
- **Supplier**: A business entity that receives cheque payments
- **Bank_Account**: A financial account with a tracked balance
- **Notification**: An in-app or email message sent to users
- **Forecast**: ML-generated prediction of future cash outflows
- **API_Gateway**: AWS API Gateway REST API endpoint
- **Lambda_Function**: AWS Lambda serverless function
- **DynamoDB_Table**: The single-table database storing all entities
- **S3_Bucket**: Private storage for cheque images
- **Textract_Service**: AWS OCR service for extracting cheque data
- **Cognito_Pool**: AWS Cognito User Pool for authentication
- **EventBridge_Rule**: Scheduled trigger for automated workflows
- **SageMaker_Job**: ML training or inference job
- **Transaction_Record**: Audit log entry for balance changes
- **Pre_Signed_URL**: Temporary authenticated URL for S3 access
- **JWT_Token**: JSON Web Token for API authorization

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a system administrator, I want secure user authentication and authorization, so that only authorized users can access their financial data.

#### Acceptance Criteria

1. THE Cognito_Pool SHALL authenticate users and issue JWT_Tokens
2. WHEN a user attempts to access the API_Gateway, THE System SHALL validate the JWT_Token
3. THE System SHALL reject requests with invalid or expired JWT_Tokens
4. WHEN a user successfully authenticates, THE System SHALL include userId in all subsequent operations
5. THE System SHALL isolate data by userId to prevent cross-user data access
6. THE Cognito_Pool SHALL support password policies with minimum complexity requirements
7. THE Cognito_Pool SHALL support multi-factor authentication as an optional feature

### Requirement 2: Cheque Management Operations

**User Story:** As a finance manager, I want to create, read, update, and delete cheque records, so that I can track all supplier payments.

#### Acceptance Criteria

1. WHEN a user creates a cheque, THE System SHALL store it in DynamoDB_Table with PK=USER#{userId} and SK=CHEQUE#{chequeId}
2. WHEN a user creates a cheque, THE System SHALL validate that supplierId and bankAccountId exist
3. WHEN a user requests cheque details, THE System SHALL return only cheques belonging to that userId
4. WHEN a user updates a cheque status, THE System SHALL validate the status transition is valid
5. WHEN a user deletes a cheque, THE System SHALL perform soft deletion by marking it as deleted
6. THE System SHALL generate unique chequeId values for each new cheque
7. WHEN a cheque is created, THE System SHALL record createdAt timestamp

### Requirement 3: Supplier Management Operations

**User Story:** As a finance manager, I want to manage supplier information, so that I can maintain accurate contact details and payment terms.

#### Acceptance Criteria

1. WHEN a user creates a supplier, THE System SHALL store it in DynamoDB_Table with PK=USER#{userId} and SK=SUPPLIER#{supplierId}
2. THE System SHALL validate that email addresses follow valid email format
3. THE System SHALL validate that phone numbers are non-empty
4. WHEN a user requests supplier list, THE System SHALL return only suppliers belonging to that userId
5. WHEN a user updates supplier information, THE System SHALL preserve the supplierId
6. WHEN a user deletes a supplier with associated cheques, THE System SHALL prevent deletion and return an error

### Requirement 4: Bank Account Management and Balance Tracking

**User Story:** As a finance manager, I want to track multiple bank account balances, so that I can monitor available funds across accounts.

#### Acceptance Criteria

1. WHEN a user creates a bank account, THE System SHALL store it in DynamoDB_Table with PK=USER#{userId} and SK=BANK#{accountId}
2. THE System SHALL initialize currentBalance to the provided value
3. WHEN a cheque status changes to cleared, THE System SHALL deduct the cheque amount from the associated Bank_Account balance
4. WHEN a bank balance is updated, THE System SHALL create a Transaction_Record with timestamp and amount
5. WHEN a bank balance is updated, THE System SHALL update the lastUpdated timestamp
6. THE System SHALL prevent bank account deletion if active cheques reference it
7. THE System SHALL maintain balance accuracy to two decimal places

### Requirement 5: Cheque Image Storage and OCR Processing

**User Story:** As a finance manager, I want to upload cheque images and automatically extract data, so that I can reduce manual data entry errors.

#### Acceptance Criteria

1. WHEN a user requests to upload a cheque image, THE System SHALL generate a Pre_Signed_URL for S3_Bucket upload
2. THE S3_Bucket SHALL store images at path userId/cheques/{chequeId}.jpg
3. THE S3_Bucket SHALL enable server-side encryption for all objects
4. WHEN an image is uploaded to S3_Bucket, THE System SHALL trigger a Lambda_Function
5. THE Lambda_Function SHALL invoke Textract_Service to extract cheque number, amount, date, and payee name
6. WHEN Textract_Service completes extraction, THE System SHALL update the cheque record with parsed data
7. THE System SHALL store the S3 imageUrl in the cheque record
8. IF Textract_Service extraction fails, THEN THE System SHALL log the error and continue without updating parsed fields

### Requirement 6: Automated Payment Reminder System

**User Story:** As a finance manager, I want automated reminders for upcoming cheque clearances, so that I can ensure sufficient funds are available.

#### Acceptance Criteria

1. THE EventBridge_Rule SHALL trigger a Lambda_Function daily at a configured time
2. WHEN the reminder Lambda_Function executes, THE System SHALL query cheques with chequeDate in 5 days
3. WHEN the reminder Lambda_Function executes, THE System SHALL query cheques with chequeDate tomorrow
4. FOR ALL cheques identified, THE System SHALL create Notification records with type=in-app
5. FOR ALL cheques identified, THE System SHALL publish messages to SNS topic for email delivery
6. THE System SHALL include cheque details (supplier, amount, date) in notification messages
7. WHEN a notification is created, THE System SHALL set read=false and record dateSent timestamp

### Requirement 7: Email Notification Delivery

**User Story:** As a finance manager, I want to receive email notifications for important events, so that I stay informed about payment obligations.

#### Acceptance Criteria

1. WHEN a message is published to SNS topic, THE System SHALL deliver it via SES to the user's email
2. THE System SHALL format email messages with clear subject lines and structured content
3. THE System SHALL include cheque details and action items in email body
4. IF email delivery fails, THEN THE System SHALL retry according to SNS retry policy
5. THE System SHALL log all email delivery attempts and outcomes

### Requirement 8: In-App Notification Management

**User Story:** As a user, I want to view and manage in-app notifications, so that I can track system alerts and reminders.

#### Acceptance Criteria

1. WHEN a user requests notifications, THE System SHALL return all Notification records for that userId
2. THE System SHALL order notifications by dateSent in descending order
3. WHEN a user marks a notification as read, THE System SHALL update read=true
4. THE System SHALL store notifications in DynamoDB_Table with PK=USER#{userId} and SK=NOTIF#{timestamp}
5. THE System SHALL support filtering notifications by read status

### Requirement 9: ML-Based Cash Flow Forecasting

**User Story:** As a finance manager, I want ML-generated cash flow forecasts, so that I can plan for future payment obligations.

#### Acceptance Criteria

1. THE EventBridge_Rule SHALL trigger ML forecast Lambda_Function weekly
2. WHEN the ML Lambda_Function executes, THE System SHALL retrieve historical cheque data for the userId
3. THE System SHALL prepare time-series data with dates and outflow amounts
4. THE Lambda_Function SHALL submit a batch job to SageMaker_Job for forecasting
5. WHEN SageMaker_Job completes, THE System SHALL store forecast results in DynamoDB_Table with PK=USER#{userId} and SK=FORECAST#{dateRange}
6. THE System SHALL store predicted outflow amounts for future dates
7. IF SageMaker_Job fails, THEN THE System SHALL log the error and retry according to configured policy

### Requirement 10: Report Generation and Export

**User Story:** As a finance manager, I want to export cheque data to Excel format, so that I can perform offline analysis and share reports.

#### Acceptance Criteria

1. WHEN a user requests a report, THE System SHALL query cheque records based on provided filters
2. THE Lambda_Function SHALL generate an Excel file with cheque data including all fields
3. THE System SHALL store the generated file in S3_Bucket with a unique filename
4. THE System SHALL generate a Pre_Signed_URL for file download with expiration time
5. THE System SHALL return the Pre_Signed_URL to the user
6. THE System SHALL include headers in the Excel file for all columns
7. THE System SHALL format dates and currency values appropriately in the Excel file

### Requirement 11: API Gateway Routing and Integration

**User Story:** As a developer, I want well-organized API endpoints, so that I can integrate the frontend with the backend efficiently.

#### Acceptance Criteria

1. THE API_Gateway SHALL expose REST endpoints organized by domain: /cheques, /suppliers, /bank-accounts, /notifications, /reports, /forecasts
2. THE API_Gateway SHALL use Cognito_Pool as the authorizer for all protected endpoints
3. WHEN a request arrives, THE API_Gateway SHALL validate the JWT_Token before invoking Lambda_Function
4. THE API_Gateway SHALL pass userId from JWT_Token to Lambda_Function in request context
5. THE API_Gateway SHALL return appropriate HTTP status codes for success and error conditions
6. THE API_Gateway SHALL enable CORS for frontend integration
7. THE API_Gateway SHALL log all requests to CloudWatch

### Requirement 12: Data Persistence and Single Table Design

**User Story:** As a system architect, I want efficient data storage using DynamoDB single table design, so that the system is cost-effective and performant.

#### Acceptance Criteria

1. THE DynamoDB_Table SHALL use PK (partition key) and SK (sort key) as the primary key
2. THE System SHALL implement entity patterns: USER#{userId}, SUPPLIER#{supplierId}, BANK#{accountId}, CHEQUE#{chequeId}, NOTIF#{timestamp}, FORECAST#{dateRange}
3. THE DynamoDB_Table SHALL enable encryption at rest
4. THE DynamoDB_Table SHALL enable point-in-time recovery for data protection
5. WHERE query patterns require it, THE System SHALL create Global Secondary Indexes
6. THE System SHALL implement optimistic locking for concurrent updates where necessary
7. THE System SHALL use consistent read operations for critical financial data

### Requirement 13: Security and Access Control

**User Story:** As a security officer, I want comprehensive security controls, so that financial data is protected from unauthorized access.

#### Acceptance Criteria

1. THE S3_Bucket SHALL block all public access
2. THE S3_Bucket SHALL enable server-side encryption with AWS managed keys
3. THE Lambda_Function SHALL use IAM roles with least privilege permissions
4. THE System SHALL log all API access attempts to CloudWatch
5. THE DynamoDB_Table SHALL enable encryption at rest
6. THE System SHALL validate all input data to prevent injection attacks
7. THE System SHALL sanitize error messages to prevent information disclosure

### Requirement 14: Monitoring and Observability

**User Story:** As a system operator, I want comprehensive monitoring and logging, so that I can detect and resolve issues quickly.

#### Acceptance Criteria

1. THE System SHALL log all Lambda_Function executions to CloudWatch
2. THE System SHALL create CloudWatch alarms for Lambda_Function errors exceeding threshold
3. THE System SHALL create CloudWatch alarms for API_Gateway 5xx errors exceeding threshold
4. THE System SHALL log all DynamoDB_Table throttling events
5. THE System SHALL create CloudWatch alarms for SageMaker_Job failures
6. THE System SHALL track API_Gateway request latency metrics
7. THE System SHALL enable X-Ray tracing for distributed request tracking

### Requirement 15: Error Handling and Resilience

**User Story:** As a system operator, I want robust error handling and retry mechanisms, so that transient failures do not cause data loss.

#### Acceptance Criteria

1. WHEN a Lambda_Function encounters an error, THE System SHALL log detailed error information
2. THE System SHALL implement exponential backoff for retryable operations
3. WHEN a DynamoDB_Table operation fails due to throttling, THE System SHALL retry with backoff
4. THE System SHALL implement idempotency for critical operations using idempotency keys
5. WHEN an external service call fails, THE System SHALL return appropriate error codes to the client
6. THE System SHALL use dead letter queues for failed asynchronous operations
7. THE System SHALL validate all input parameters before processing

### Requirement 16: Cheque Status Workflow Management

**User Story:** As a finance manager, I want controlled cheque status transitions, so that cheque lifecycle is accurately tracked.

#### Acceptance Criteria

1. THE System SHALL support status values: issued, upcoming, cleared, bounced, cancelled
2. WHEN a cheque status changes from any status to cleared, THE System SHALL update the associated Bank_Account balance
3. WHEN a cheque status changes to cleared, THE System SHALL create a Transaction_Record
4. THE System SHALL prevent invalid status transitions
5. WHEN a cheque status changes to bounced, THE System SHALL create a Notification
6. WHEN a cheque status changes to cancelled, THE System SHALL not affect Bank_Account balance
7. THE System SHALL record status change timestamp and userId who made the change

### Requirement 17: Transaction Audit Trail

**User Story:** As an auditor, I want complete transaction history, so that I can verify all balance changes.

#### Acceptance Criteria

1. WHEN a Bank_Account balance changes, THE System SHALL create a Transaction_Record
2. THE Transaction_Record SHALL include timestamp, userId, chequeId, amount, and previous balance
3. THE System SHALL store Transaction_Record in DynamoDB_Table with queryable pattern
4. THE System SHALL never delete Transaction_Record entries
5. WHEN a user requests transaction history, THE System SHALL return records in chronological order
6. THE Transaction_Record SHALL be immutable after creation
7. THE System SHALL validate that transaction amounts match cheque amounts

### Requirement 18: Infrastructure as Code Support

**User Story:** As a DevOps engineer, I want infrastructure defined as code, so that I can deploy and manage the system consistently.

#### Acceptance Criteria

1. THE System SHALL support deployment via AWS CDK, CloudFormation, or Terraform
2. THE infrastructure code SHALL define all AWS resources with appropriate configurations
3. THE infrastructure code SHALL parameterize environment-specific values
4. THE infrastructure code SHALL define IAM roles and policies for all services
5. THE infrastructure code SHALL configure CloudWatch alarms and monitoring
6. THE infrastructure code SHALL enable resource tagging for cost allocation
7. THE infrastructure code SHALL support multiple deployment environments (dev, staging, prod)

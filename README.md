# Claims Service

Serverless architecture for managing insurance claims.

## Structure

- `src/functions`: Lambda functions
  - `create-claim`: FNOL API
  - `process-claim`: Core processing logic
  - `send-notification`: Email notifications
- `src/shared`: Shared types and utilities
- `infra`: Infrastructure code

## Prerequisites for Event-Driven Architecture

To build this event-driven system with SNS & SQS, here is what was required conceptually and in the infrastructure:

### 1. Conceptual Design

- **Decoupling**: Identify which parts of your system can run asynchronously (e.g., sending emails, processing heavy calculations).
- **Fan-Out Pattern**: Decide if one event needs to trigger multiple downstream actions (e.g., `Claim.Created` -> `Process Claim` AND `Archive Claim`).

### 2. Infrastructure Requirements (Terraform Setup)

These are the specific resources we provisioned in the `infra` folder:

- **SNS Topic (`aws_sns_topic`)**:
  - The "Subject" that producers publish to.
  - _Required:_ A unique name.

- **SQS Queue (`aws_sqs_queue`)**:
  - The "Inbox" for the consumer.
  - _Required:_ Redrive Policy (linking to a Dead Letter Queue) for error handling.

- **SNS Subscription (`aws_sns_topic_subscription`)**:
  - The "Link" that tells SNS to send messages to SQS.
  - _Protocol:_ `sqs`.
  - _Endpoint:_ The ARN of the SQS Queue.

- **Queue Policy (`aws_sqs_queue_policy`)**:
  - **CRITICAL STEP**: By default, SQS is private. We explicitly added a policy allowing the **SNS Service Principal (`sns.amazonaws.com`)** to perform `sqs:SendMessage` on our queue. Without this, messages will be lost.

- **IAM Policies for Lambda**:
  - **Producer (`create-claim`)**: Needs `sns:Publish` permission on the Topic ARN.
  - **Consumer (`process-claim`)**: Needs `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:GetQueueAttributes` on the Queue ARN.

## Infrastructure Architecture

I have set up a **Fan-Out Architecture** using SNS and SQS to decouple your services and ensure reliable processing.

```mermaid
architecture-beta
    group api(logos:aws-api-gateway)[API Layer]
    group processing(logos:aws-lambda)[Compute]
    group messaging(logos:aws-sns)[Messaging & Fan-out]
    group storage(logos:aws-dynamodb)[Storage]

    service apiGateway(logos:aws-api-gateway)[API Gateway] in api
    service createClaim(logos:aws-lambda)[Create Claim Lambda] in processing
    service processClaim(logos:aws-lambda)[Process Claim Lambda] in processing
    service sendNotify(logos:aws-lambda)[Send Notification Lambda] in processing

    service sns(logos:aws-sns)[SNS Topic] in messaging
    service sqs(logos:aws-sqs)[SQS Queue] in messaging
    service dlq(logos:aws-sqs)[DLQ] in messaging

    service dynamo(logos:aws-dynamodb)[DynamoDB] in storage
    service ses(logos:aws-ses)[Email Service]

    apiGateway:R -- L:createClaim
    createClaim:R -- L:sns
    createClaim:B -- T:dynamo

    sns:R -- L:sqs
    sns:B -- T:sendNotify

    sqs:R -- L:processClaim
    processClaim:T -- B:dynamo
    processClaim:L -- R:dlq

    sendNotify:R -- L:ses
```

### 1. The Core Messaging Infrastructure

I created a dedicated module to handle messaging resources:

- **SNS Topic (`claims_topic`)**:
  - Acts as a central "Event Bus".
  - Services publish events (like `Claim.Created`) here instead of calling other services directly.
- **SQS Queue (`claims_queue`)**:
  - Acts as a buffer for incoming jobs.
  - Subscribed to the SNS Topic. Any message sent to the topic is automatically forwarded to this queue.
- **Dead Letter Queue (DLQ) (`claims_dlq`)**:
  - **Safety net:** If a message fails to process 3 times (configured via `redrive_policy`), it is moved here. This prevents data loss and allows you to debug failed messages later.
- **Queue Policy**:
  - Configured permissions to securely allow the SNS topic to write messages to the SQS queue.

### 2. Integration with Compute

The Lambda functions were updated to interact with this infrastructure:

- **`create_claim` Lambda**:
  - **Publisher:** Instead of processing everything immediately, it simply saves to the DB and **Publishes** an event to the SNS Topic. This makes the API fast and responsive.

- **`process_claim` Lambda**:
  - **Consumer:** Triggered automatically by the **SQS Queue**.
  - It processes claims in the background (asynchronously).
  - If it crashes, SQS will retry, and eventually settle in the DLQ if it keeps failing.

- **`send_notification` Lambda**:
  - **Filtered Subscriber:** Subscribed directly to the SNS Topic, but with a **Filter Policy**.
  - It _only_ triggers for specific events (`Claim.Accepted`, `Claim.Rejected`). It ignores the initial `Claim.Created` events, saving costs and computing power.

### Why this setup?

1.  **Decoupling:** The `create_claim` function doesn't need to know `process_claim` exists. It just announces "A claim was created!" and moves on.
2.  **Reliability:** If `process_claim` is overwhelmed or failing, SQS holds the messages safely.
3.  **Extensibility:** IF you later want to add an "Analytics Service" that listens to all claims, you just add another SQS queue subscribed to the same SNS topic. You don't have to touch the `create_claim` code.

## Setup

1. `npm install`
2. `npm run build`

## Testing Flow

### 1. Create a Claim (Trigger)

Since we haven't provisioned an API Gateway yet, you can test this by manually invoking the `create-claim` Lambda function via the AWS Console or CLI.

**Payload:**

```json
{
  "body": "{\"amount\": 800, \"description\": \"Broken windshield\"}"
}
```

### 2. What Happens Next? (The Flow)

1.  **`create-claim` Lambda**:
    - Receives the payload.
    - Generates a Claim ID (e.g., `123-abc`).
    - **Publishes** `Claim.Requested` event to the **SNS Topic**.
    - (It does _not_ write to DynamoDB yet).

2.  **Infrastructure (SNS & SQS)**:
    - The SNS Topic receives the event.
    - It forwards the message to the subscribed **SQS Queue**.

3.  **`process-claim` Lambda**:
    - Polls the SQS Queue and picks up the message.
    - **Creates** the claim in DynamoDB (Status: `RECEIVED`).
    - **Checks Business Rule**: Is `amount < 1000`?
      - **Yes (800)**: Updates status to `ACCEPTED`.
      - **No**: Updates status to `REJECTED`.
    - **Publishes** the decision (`Claim.Accepted`) back to the **SNS Topic**.

4.  **`send-notification` Lambda**:
    - This Lambda is subscribed to the SNS Topic (filtered for Accepted/Rejected).
    - It triggers, reads the message.
    - **Sends an Email** via AWS SES to `user@example.com`.

### 3. Verification

- Check **DynamoDB**: You should see the item with status `ACCEPTED`.
- Check **CloudWatch Logs**: see the logs for each Lambda.
- Check **Email**: If you verified your email in SES Sandbox, you will receive an email.

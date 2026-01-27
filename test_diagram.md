# Test Diagram

```mermaid
architecture-beta
    group api(logos:aws-api-gateway)[API Gateway]
    service lambda(logos:aws-lambda)[Lambda] in api
    service db(logos:aws-dynamodb)[DynamoDB]

    lambda:R -- L:db
```

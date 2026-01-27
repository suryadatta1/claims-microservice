import { SQSEvent, SQSHandler } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
import { Claim, ClaimEvent } from '../../shared/types';

const dbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dbClient);
const snsClient = new SNSClient({});

const TABLE_NAME = process.env.CLAIMS_TABLE_NAME;
const TOPIC_ARN = process.env.TOPIC_ARN;

export const handler: SQSHandler = async (event: SQSEvent) => {
  for (const record of event.Records) {
    try {
      console.log('Processing SQS Record:', record.body);
      
      const snsNotification = JSON.parse(record.body);
      const messageBody = snsNotification.Message;
      
      if (!messageBody) {
          console.error('No Message found in SNS envelope');
          continue;
      }

      const claimEvent = JSON.parse(messageBody) as ClaimEvent;

      if (claimEvent.type === 'Claim.Requested') {
          const claim = claimEvent.payload as Claim;
          
          if (!claim || !claim.id) {
              console.error('Invalid claim data in event payload');
              continue;
          }

          console.log(`Creating claim ${claim.id} in DynamoDB...`);

          // 1. Create Claim 
          await docClient.send(new PutCommand({
            TableName: TABLE_NAME,
            Item: claim,
          }));
          
          // 2. Business Rule Processing
           let newStatus: Claim['status'] = 'REJECTED';
           if (claim.amount < 1000) {
             newStatus = 'ACCEPTED';
           }

           // 3. Update Claim
           await docClient.send(new UpdateCommand({
             TableName: TABLE_NAME,
             Key: { id: claim.id },
             UpdateExpression: 'set #s = :s',
             ExpressionAttributeNames: { '#s': 'status' },
             ExpressionAttributeValues: { ':s': newStatus },
           }));

           // 4. Publish Decision Event to SNS
           const eventType = newStatus === 'ACCEPTED' ? 'Claim.Accepted' : 'Claim.Rejected';
           const resultEvent: ClaimEvent = {
             id: claim.id,
             type: eventType,
             payload: { ...claim, status: newStatus }
           };
           
           console.log(`Publishing ${eventType} to SNS:`, JSON.stringify(resultEvent, null, 2));

           if (TOPIC_ARN) {
               await snsClient.send(new PublishCommand({
                   TopicArn: TOPIC_ARN,
                   Message: JSON.stringify(resultEvent),
                   MessageAttributes: {
                       'event_type': {
                           DataType: 'String',
                           StringValue: eventType
                       }
                   }
               }));
           } else {
               console.warn('TOPIC_ARN not set, skipping SNS publish for decision');
           }
           
      } else {
          console.warn('Unknown event type received:', claimEvent.type);
      }

    } catch (error) {
      console.error('Error processing record:', error);
      throw error; 
    }
  }
};

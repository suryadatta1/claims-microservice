import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
import { v4 as uuidv4 } from 'uuid';
import { Claim, ClaimEvent } from '../../shared/types';

const client = new SNSClient({});
const TOPIC_ARN = process.env.TOPIC_ARN;

export const handler = async (event: any) => {
  console.log('Received claim creation request:', JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body || '{}');
    const { amount, description } = body;

    if (!amount || !description) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Missing required fields: amount, description' }),
      };
    }

    if (!TOPIC_ARN) {
        throw new Error('TOPIC_ARN environment variable is not defined');
    }

    const claim: Claim = {
      id: uuidv4(),
      status: 'RECEIVED',
      amount: Number(amount),
      description,
      createdAt: new Date().toISOString(),
    };

    const claimEvent: ClaimEvent = {
        id: claim.id,
        type: 'Claim.Requested',
        payload: claim
    };

    console.log('Publishing Claim.Requested to SNS:', JSON.stringify(claimEvent, null, 2));

    await client.send(new PublishCommand({
      TopicArn: TOPIC_ARN,
      Message: JSON.stringify(claimEvent),
      MessageAttributes: {
          'event_type': {
              DataType: 'String',
              StringValue: 'Claim.Requested'
          }
      }
    }));

    return {
      statusCode: 202, // Accepted
      body: JSON.stringify({ message: 'Claim creation request received', id: claim.id }),
    };
  } catch (error) {
    console.error('Error creating claim:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    };
  }
};

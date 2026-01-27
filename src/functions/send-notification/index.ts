import { SNSHandler } from 'aws-lambda';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { ClaimEvent } from '../../shared/types';

const sesClient = new SESClient({});

const FROM_EMAIL = process.env.FROM_EMAIL;
const TO_EMAIL = process.env.TO_EMAIL;

export const handler: SNSHandler = async (event) => {
  console.log('Received SNS event:', JSON.stringify(event, null, 2));

  // Validate required environment variables
  if (!FROM_EMAIL || !TO_EMAIL) {
    throw new Error('FROM_EMAIL and TO_EMAIL environment variables must be set');
  }

  for (const record of event.Records) {
      try {
          const message = record.Sns.Message;
          const msgAttributes = record.Sns.MessageAttributes;
          
          console.log(`Processing Message:`, message);
          
          const claimEvent = JSON.parse(message) as ClaimEvent;
          const claim = claimEvent.payload;
          const eventType = claimEvent.type;

          if (!claim || !claim.id) {
            console.error('Invalid event detail: missing claim data');
            continue;
          }

          // Email Construction
          const recipient = TO_EMAIL;
          let subject = '';
          let body = '';

          if (eventType === 'Claim.Accepted') {
            subject = `Claim ${claim.id} Accepted`;
            body = `Dear User,\n\nYour claim for amount $${claim.amount} has been accepted.\n\nDescription: ${claim.description}`;
          } else if (eventType === 'Claim.Rejected') {
            subject = `Claim ${claim.id} Rejected`;
            body = `Dear User,\n\nYour claim for amount $${claim.amount} has been rejected.\n\nDescription: ${claim.description}`;
          } else {
            console.warn(`Unhandled event type: ${eventType}`);
            continue;
          }

          // Sending Email via AWS SES
          console.log(`Sending Email from ${FROM_EMAIL} to ${recipient}`);
          
          await sesClient.send(new SendEmailCommand({
            Source: FROM_EMAIL,
            Destination: {
                ToAddresses: [recipient as string]
            },
            Message: {
                Subject: { Data: subject },
                Body: {
                    Text: { Data: body }
                }
            }
          }));
          
          console.log('Email sent successfully');

      } catch (error) {
          console.error('Error processing SNS record or sending email:', error);
          // Don't throw if you want to skip bad records, or throw to retry
      }
  }
};

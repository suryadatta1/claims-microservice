import { SNSHandler } from 'aws-lambda';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { ClaimEvent } from '../../shared/types';

const sesClient = new SESClient({});

export const handler: SNSHandler = async (event) => {
  console.log('Received SNS event:', JSON.stringify(event, null, 2));

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

          // Simulate Email Construction
          const recipient = 'user@example.com';
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
          console.log(`Sending Email via SES to ${recipient}`);
          
          await sesClient.send(new SendEmailCommand({
            Source: 'no-reply@claims-service.com', // Needs to be a verified identity in SES Sandbox
            Destination: {
                ToAddresses: [recipient]
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

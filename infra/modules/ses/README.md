# AWS SES Email Setup for Claims System

## Overview

This module sets up AWS Simple Email Service (SES) to enable the `send-notification` Lambda function to send emails when claims are accepted or rejected.

## What's Configured

### Email Identities

- **From Email**: `suryadattatangirala@outlook.com` - verified identity for sending emails
- **To Email**: `tangiralasuryadatta@gmail.com` - verified identity for receiving emails

### SES Configuration Set

- Name: `claims-email-config-prod`
- TLS Policy: Required (encrypted email transmission)

## Important: Email Verification

### AWS SES Sandbox Mode

By default, AWS SES accounts start in **sandbox mode**, which means:

- ✉️ You can ONLY send emails to **verified email addresses**
- 📊 Sending limit: 200 emails per 24 hours
- 📈 Rate limit: 1 email per second

### Verification Steps Required

After running `terraform apply`, you MUST:

1. **Check your email inboxes** for both addresses:
   - `suryadattatangirala@outlook.com`
   - `tangiralasuryadatta@gmail.com`

2. **Click the verification links** in the AWS SES verification emails

3. **Verify both identities** - emails won't send until BOTH are verified

### How to Verify Manually (if needed)

```bash
# Check verification status
aws ses get-identity-verification-attributes \
  --identities suryadattatangirala@outlook.com tangiralasuryadatta@gmail.com \
  --region ap-south-1

# Resend verification email if needed
aws ses verify-email-identity \
  --email-address suryadattatangirala@outlook.com \
  --region ap-south-1
```

## Moving to Production

To send emails to ANY email address (not just verified ones), you need to:

1. **Request production access** in the AWS SES console
2. Go to: AWS Console → SES → Account dashboard → Request production access
3. Fill out the request form explaining your use case
4. AWS typically approves within 24 hours

### Production Benefits

- ✅ Send to ANY email address
- ✅ Higher sending limits (50,000 emails/day by default)
- ✅ Higher rate limits (14 emails/second)

## Testing Email Sending

After verification, test by:

1. Creating a claim via API
2. Processing the claim (accept/reject)
3. Check `tangiralasuryadatta@gmail.com` for the notification email

## Troubleshooting

### Emails not sending?

- Check CloudWatch Logs: `/aws/lambda/send-notification-prod`
- Verify both email identities are verified in SES console
- Check IAM permissions for Lambda (already configured)

### Common Error Messages

- `"Email address is not verified"` → Click verification link in email
- `"MessageRejected"` → Account in sandbox, verify recipient email
- `"Daily sending quota exceeded"` → Wait 24 hours or request production access

## Resources Created

- `aws_ses_email_identity.from_email` - From email verification
- `aws_ses_email_identity.to_email` - To email verification
- `aws_ses_configuration_set.main` - Email tracking configuration

## Configuration Variables

Edit in `infra/variables.tf`:

```hcl
variable "from_email" {
  default = "suryadattatangirala@outlook.com"
}

variable "to_email" {
  default = "tangiralasuryadatta@gmail.com"
}
```

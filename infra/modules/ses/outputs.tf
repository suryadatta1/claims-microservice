output "from_email_identity_arn" {
  description = "ARN of the verified from email identity"
  value       = aws_ses_email_identity.from_email.arn
}

output "to_email_identity_arn" {
  description = "ARN of the verified to email identity"
  value       = aws_ses_email_identity.to_email.arn
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}

output "from_email" {
  description = "From email address"
  value       = var.from_email
}

output "to_email" {
  description = "To email address"
  value       = var.to_email
}

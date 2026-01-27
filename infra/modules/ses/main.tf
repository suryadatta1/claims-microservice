# SES Email Identity for "From" address
resource "aws_ses_email_identity" "from_email" {
  email = var.from_email
}

# SES Email Identity for "To" address (if in sandbox mode, both need verification)
resource "aws_ses_email_identity" "to_email" {
  email = var.to_email
}

# Optional: Configuration set for tracking email metrics
resource "aws_ses_configuration_set" "main" {
  name = "claims-email-config-${var.environment}"

  delivery_options {
    tls_policy = "Require"
  }
}

variable "aws_region" {
  default = "ap-south-1"
}

variable "environment" {
  default = "prod"
}

variable "from_email" {
  description = "Email address to send notifications from (must be verified in SES)"
  type        = string
  default     = "suryadattatangirala@outlook.com"
}

variable "to_email" {
  description = "Email address to send notifications to"
  type        = string
  default     = "tangiralasuryadatta@gmail.com"
}

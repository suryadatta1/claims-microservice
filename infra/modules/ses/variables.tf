variable "environment" {
  description = "Environment (e.g., prod, dev)"
  type        = string
}

variable "from_email" {
  description = "Email address to send notifications from"
  type        = string
}

variable "to_email" {
  description = "Email address to send notifications to"
  type        = string
}

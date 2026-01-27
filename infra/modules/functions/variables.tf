variable "environment" { type = string }
variable "table_name" { type = string }
variable "table_arn" { type = string }
variable "queue_arn" { type = string }
variable "queue_url" { type = string }
variable "topic_name" { type = string }
variable "topic_arn" { type = string }
variable "from_email" {
  type        = string
  description = "Email address to send notifications from (must be verified in SES)"
  default = "suryadattatangirala@outlook.com"
}
variable "to_email" {
  type        = string
  description = "Email address to send notifications to"
  default = "tangiralasuryadatta@gmail.com"
}

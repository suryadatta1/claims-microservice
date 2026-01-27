variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "topic_name" {
  description = "Name of the SNS Topic"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

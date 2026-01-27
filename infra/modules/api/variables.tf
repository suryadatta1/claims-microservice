variable "api_name" {
  type = string
}

variable "create_claim_invoke_arn" {
  description = "The Invoke ARN of the create-claim lambda"
  type        = string
}

variable "create_claim_function_name" {
  description = "The function name of the create-claim lambda"
  type        = string
}

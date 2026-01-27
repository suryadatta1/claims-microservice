output "create_claim_function_name" {
  value = aws_lambda_function.create_claim.function_name
}

output "create_claim_invoke_arn" {
  value = aws_lambda_function.create_claim.invoke_arn
}

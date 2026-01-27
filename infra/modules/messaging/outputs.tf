output "queue_url" {
  value = aws_sqs_queue.claims_queue.url
}

output "queue_arn" {
  value = aws_sqs_queue.claims_queue.arn
}

output "dlq_url" {
  value = aws_sqs_queue.claims_dlq.url
}

output "dlq_arn" {
  value = aws_sqs_queue.claims_dlq.arn
}

output "topic_name" {
  value = aws_sns_topic.claims_topic.name
}

output "topic_arn" {
  value = aws_sns_topic.claims_topic.arn
}

resource "aws_sqs_queue" "claims_dlq" {
  name = "${var.queue_name}-dlq"
}

resource "aws_sqs_queue" "claims_queue" {
  name = var.queue_name
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.claims_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sns_topic" "claims_topic" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.claims_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.claims_queue.arn
}

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.claims_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.claims_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn": aws_sns_topic.claims_topic.arn
          }
        }
      }
    ]
  })
}

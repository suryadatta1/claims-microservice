data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "claims-lambda-exec-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Policies ---
resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = var.table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "sqs_policy" {
  name = "sqs-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = var.queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "sns_policy" {
  name = "sns-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = var.topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses_policy" {
  name = "ses-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# --- Functions ---

resource "null_resource" "build_trigger" {
  triggers = {
    src_hash     = sha256(join("", [for f in fileset("${path.module}/../../../src", "**") : filesha1("${path.module}/../../../src/${f}")]))
    package_json = filesha1("${path.module}/../../../package.json")
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/../../.."
    command     = "npm run build"
    interpreter = ["PowerShell", "-Command"]
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../dist"
  output_path = "${path.module}/lambda.zip"
  depends_on  = [null_resource.build_trigger]
}

# Create Claim
resource "aws_lambda_function" "create_claim" {
  function_name    = "create-claim-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/create-claim/index.handler"
  runtime          = "nodejs24.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLAIMS_TABLE_NAME = var.table_name
      TOPIC_ARN         = var.topic_arn
    }
  }
}

# Process Claim
resource "aws_lambda_function" "process_claim" {
  function_name    = "process-claim-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/process-claim/index.handler"
  runtime          = "nodejs24.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLAIMS_TABLE_NAME = var.table_name
      TOPIC_ARN         = var.topic_arn
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.process_claim.arn
}

# Send Notification
resource "aws_lambda_function" "send_notification" {
  function_name    = "send-notification-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "functions/send-notification/index.handler"
  runtime          = "nodejs24.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLAIMS_TABLE_NAME = var.table_name
      TOPIC_ARN         = var.topic_arn
    }
  }
}

# Subscribe Send Notification to SNS Topic (Filtered)
resource "aws_sns_topic_subscription" "notification_lambda_subscription" {
  topic_arn = var.topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_notification.arn

  filter_policy = jsonencode({
    "event_type" : ["Claim.Accepted", "Claim.Rejected"]
  })
}

resource "aws_lambda_permission" "allow_sns_invoke_notification" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.topic_arn
}

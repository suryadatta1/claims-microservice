resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "create_claim_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.create_claim_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_claim_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /claims"
  target    = "integrations/${aws_apigatewayv2_integration.create_claim_integration.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.create_claim_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/claims"
}

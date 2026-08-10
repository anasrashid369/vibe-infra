variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

# REST API (v1) — used instead of HTTP API (v2) because v2 requires a
# higher LocalStack license tier. Functionally equivalent for our needs.
resource "aws_api_gateway_rest_api" "bff" {
  name = "${var.project_name}-${var.environment}-api"
}

# A single greedy proxy resource ({proxy+}) forwards every path to the
# same Lambda integration — mirrors the "all routes -> one integration"
# shape we had with the v2 routes.
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.bff.id
  parent_id   = aws_api_gateway_rest_api.bff.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.bff.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.bff.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Also handle the bare root path ("/") the same way.
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.bff.id
  resource_id   = aws_api_gateway_rest_api.bff.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_root" {
  rest_api_id             = aws_api_gateway_rest_api.bff.id
  resource_id             = aws_api_gateway_method.proxy_root.resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "bff" {
  rest_api_id = aws_api_gateway_rest_api.bff.id

  depends_on = [
    aws_api_gateway_integration.proxy,
    aws_api_gateway_integration.proxy_root,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.bff.id
  rest_api_id   = aws_api_gateway_rest_api.bff.id
  stage_name    = var.environment
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bff.execution_arn}/*/*"
}

output "invoke_url" {
  value = aws_api_gateway_stage.default.invoke_url
}
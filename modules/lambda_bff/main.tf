variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "secrets_arn" {
  description = "ARN of the Secrets Manager secret the BFF is allowed to read."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB cache table the BFF is allowed to read/write."
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the built BFF deployment package (see vibe-bff/dist)."
  type        = string
  default     = "../vibe-bff/dist/bundle.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.environment}-bff-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-${var.environment}-bff-permissions"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.secrets_arn
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_lambda_function" "bff" {
  function_name = "${var.project_name}-${var.environment}-bff"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 15
  memory_size   = 256

  filename         = var.lambda_zip_path
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  environment {
    variables = {
      PROVIDER_SECRETS_ID = var.secrets_arn
      DYNAMODB_TABLE_ARN  = var.dynamodb_table_arn
      ENVIRONMENT         = var.environment
    }
  }
}

output "function_name" {
  value = aws_lambda_function.bff.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.bff.invoke_arn
}
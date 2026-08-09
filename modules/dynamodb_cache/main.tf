variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# Optional request/response audit log + TMDB response cache (spec §6.2).
# Not required for MVP correctness — safe to leave empty/unused until
# Phase 5's DynamoDB-backed cache work.
resource "aws_dynamodb_table" "cache" {
  name         = "${var.project_name}-${var.environment}-cache"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

output "table_arn" {
  value = aws_dynamodb_table.cache.arn
}

output "table_name" {
  value = aws_dynamodb_table.cache.name
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

resource "aws_secretsmanager_secret" "provider_keys" {
  name        = "${var.project_name}/${var.environment}/provider-keys"
  description = "TMDB + LLM provider API keys, read once at BFF cold start."
}

# Placeholder version so `terraform apply` succeeds against LocalStack from
# a clean checkout without requiring real keys. Real values are set via
# `aws secretsmanager put-secret-value` (or console/CLI against prod) —
# never committed to this repo.
resource "aws_secretsmanager_secret_version" "provider_keys" {
  secret_id = aws_secretsmanager_secret.provider_keys.id
  secret_string = jsonencode({
    tmdbApiKey   = "REPLACE_ME"
    geminiApiKey = "REPLACE_ME"
    claudeApiKey = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

output "secret_arn" {
  value = aws_secretsmanager_secret.provider_keys.arn
}

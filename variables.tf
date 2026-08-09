variable "use_localstack" {
  description = "If true, point the AWS provider at a local LocalStack instance instead of real AWS."
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "Real AWS access key. Unused when use_localstack = true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Real AWS secret key. Unused when use_localstack = true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "project_name" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "vibe"
}

variable "environment" {
  description = "Deployment environment name (local, staging, prod)."
  type        = string
  default     = "local"
}

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
}

module "dynamodb_cache" {
  source = "./modules/dynamodb_cache"

  project_name = var.project_name
  environment  = var.environment
}

module "lambda_bff" {
  source = "./modules/lambda_bff"

  project_name       = var.project_name
  environment        = var.environment
  secrets_arn        = module.secrets.secret_arn
  dynamodb_table_arn = module.dynamodb_cache.table_arn
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_invoke_arn    = module.lambda_bff.invoke_arn
  lambda_function_name = module.lambda_bff.function_name
}

output "api_endpoint" {
  description = "Base URL for the BFF API."
  value       = module.api_gateway.invoke_url
}

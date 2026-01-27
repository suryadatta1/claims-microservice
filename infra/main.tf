module "database" {
  source      = "./modules/database"
  environment = var.environment
  table_name  = "ClaimsTable-${var.environment}"
}

module "messaging" {
  source      = "./modules/messaging"
  queue_name  = "claims-queue-${var.environment}"
  topic_name  = "claims-topic-${var.environment}"
}

module "compute" {
  source      = "./modules/functions"
  environment = var.environment
  
  table_name  = module.database.table_name
  table_arn   = module.database.table_arn
  
  queue_url   = module.messaging.queue_url
  queue_arn   = module.messaging.queue_arn
  
  topic_name  = module.messaging.topic_name
  topic_arn   = module.messaging.topic_arn
}

module "api" {
  source                     = "./modules/api"
  api_name                   = "claims-api-${var.environment}"
  create_claim_invoke_arn    = module.compute.create_claim_invoke_arn
  create_claim_function_name = module.compute.create_claim_function_name
}

output "api_endpoint" {
  value = module.api.api_endpoint
}

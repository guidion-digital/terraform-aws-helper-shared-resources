output "vpc" {
  description = "Map of VPC and its attributes"
  value       = module.vpc
}

output "secrets" {
  description = "Map of secrets and their attributes"
  value       = module.secrets
}

output "rds" {
  description = "Map of RDS instances and their attributes"
  value       = module.rds
}

output "memcached" {
  description = "Map of Memcached clusters and their attributes"
  value       = module.elasticache
}

output "dyanmodb_table_stream_arns" {
  description = "ARNs of any DynamoDB tables that get created"
  value       = module.supporting_resources.dyanmodb_table_stream_arns
}

output "dynamodb" {
  description = "Map of DynamoDB tables and their attributes"
  value       = module.supporting_resources.dynamodb
}

output "sqs" {
  description = "Map of SQS queues and their attributes"
  value       = module.supporting_resources.sqs
}

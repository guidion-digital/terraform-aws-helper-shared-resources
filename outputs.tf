output "vpc" {
  description = "Map of VPC and its attributes"
  value       = module.vpc
}

output "secrets" {
  description = "Map of secrets and their attributes"
  value       = module.secrets
}

output "ssm_parameters" {
  description = "Map of SSM parameters and their attributes"
  value       = module.ssm_parameters
}

output "rds" {
  description = "Map of RDS instances and their attributes"
  value       = module.rds
}

output "redshift" {
  description = "Map of Redshift clusters and their attributes"
  value       = module.redshift
}

output "memcached" {
  description = "DEPRECATED: Use elasticache output instead"
  value       = module.elasticache
}

output "elasticache" {
  description = "Map of Elasticache clusters and their attributes (both Redis and Memcached)"
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

output "rds_proxy_connect_role_arns" {
  description = "ARNs of the RDS proxy connect roles"
  value       = { for this_db, this_config in module.rds : this_db => aws_iam_role.rds_proxy_connect[this_db].arn }
}

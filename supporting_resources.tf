module "supporting_resources" {
  source  = "guidion-digital/helper-supporting-resources/aws"
  version = "3.0.0"

  namespacing_enabled = var.namespace_supporting_resources
  application_name    = var.application_name
  tags                = local.tags
  sqs_queues          = var.sqs_queues
  dynamodb_tables     = var.dynamodb_tables
}

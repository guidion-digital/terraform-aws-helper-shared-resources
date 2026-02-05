variable "application_name" { default = "redshift-example" }
variable "project" { default = "constr" }
variable "stage" { default = "development" }
variable "grafana_promtail_lambda_arn" { default = "arn:aws:lambda:eu-central-1:000000000000:function:grafana-promtail-lambda" }
variable "vpc_config" {
  default = {
    vpc_cidr                = "10.126.3.0/24"
    transit_gateway_enabled = false
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "shared_resources" {
  source = "../../"

  # Required variables
  application_name               = var.application_name
  namespace_supporting_resources = true
  stage                          = var.stage
  region                         = data.aws_region.current.region
  account_id                     = data.aws_caller_identity.current.account_id
  project                        = var.project
  grafana_promtail_lambda_arn    = var.grafana_promtail_lambda_arn

  # Optional variables
  vpc_config = var.vpc_config

  redshift_instances = {
    "example" = {
      node_type             = "ra3.large"
      number_of_nodes       = 2
      publicly_accessible   = true
      enhanced_vpc_routing  = true
      allow_version_upgrade = false
    }
  }
}

output "redshift" {
  value = module.shared_resources.redshift
}

output "vpc" {
  value = module.shared_resources.vpc
}

variable "application_name" { default = "redshift-example" }
variable "project" { default = "constr" }
variable "stage" { default = "development" }
variable "grafana_promtail_lambda_arn" { default = "arn:aws:lambda:eu-central-1:000000000000:function:grafana-promtail-lambda" }
variable "vpc_config" {
  default = {
    vpc_cidr                = "10.126.3.0/24"
    transit_gateway_enabled = true
    public_subnet_enabled   = true
    private_subnet_enabled  = false
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "tfe_outputs" "networking" {
  organization = "guidion"
  workspace    = "networking"
}

module "shared_resources" {
  source = "../../"

  # Required variables
  application_name                  = var.application_name
  namespace_supporting_resources    = true
  stage                             = var.stage
  region                            = data.aws_region.current.region
  account_id                        = data.aws_caller_identity.current.account_id
  project                           = var.project
  grafana_promtail_lambda_arn       = var.grafana_promtail_lambda_arn
  public_subnet_prefix_list_entries = data.tfe_outputs.networking.nonsensitive_values.tgw_attached_networks

  # Optional variables
  vpc_config = var.vpc_config

  redshift_instances = {
    "example" = {
      node_type              = "ra3.large"
      number_of_nodes        = 1
      publicly_accessible    = true
      enhanced_vpc_routing   = true
      allow_version_upgrade  = false
      vpc_security_group_ids = []
      ingress_whitelist_cidrs = [
        {
          cidr        = "10.0.0.0/8"
          description = "Allow internal network access to Redshift"
        },
        {
          cidr        = "18.192.2.142/32"
          description = "Metabase Cloud"
        },
        {
          cidr        = "10.120.2.0/24"
          description = "AWS Client VPN"
        },
        {
          cidr        = "172.31.0.0/16"
          description = "Redshift (Mailman)"
        },
        {
          cidr        = "3.65.184.173/32"
          description = "Metabase Cloud"
        },
        {
          cidr        = "10.192.0.0/16"
          description = "MWAA Airflow"
        },
        {
          cidr        = "10.168.1.0/24"
          description = "guidion-data-acceptance-ecs"
        },
        {
          cidr        = "10.128.1.0/24"
          description = "guidion-data-development-ecs"
        },
        {
          cidr        = "10.208.0.0/24"
          description = "guidion-data-production-powerbi-gateway"
        },
        {
          cidr        = "18.184.191.58/32"
          description = "Metabase Cloud"
        }
      ]

      # snapshot_arn = ""
      # owner_account = ""
    }
  }
}

# Disabled because it contains sensitive values
# output "redshift" {
#   value = module.shared_resources.redshift
# }

output "vpc" {
  value = module.shared_resources.vpc
}

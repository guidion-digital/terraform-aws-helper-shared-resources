locals {
  transit_gateway_enabled = var.vpc_config != null ? var.vpc_config.transit_gateway_enabled : false
}

data "aws_ec2_transit_gateway" "this" {
  count = local.transit_gateway_enabled ? 1 : 0

  filter {
    name   = "state"
    values = ["available"]
  }
}

module "vpc" {
  count = var.vpc_config != null ? 1 : 0

  source  = "aws-ia/vpc/aws"
  version = "4.4.4"

  name               = local.name
  cidr_block         = var.vpc_config.vpc_cidr
  az_count           = var.vpc_config.az_count
  transit_gateway_id = var.vpc_config.transit_gateway_enabled ? one(data.aws_ec2_transit_gateway.this).id : null
  tags               = local.tags

  transit_gateway_routes = var.vpc_config.transit_gateway_enabled ? {
    private = "0.0.0.0/0"
  } : {}

  # This isn't exactly right, since the fallback only describes the private netmask
  subnets = var.vpc_config.transit_gateway_enabled ? {
    private = {
      netmask = 26
    }

    transit_gateway = {
      netmask                                         = 28
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
      transit_gateway_appliance_mode_support          = "disable"
      transit_gateway_dns_support                     = "disable"
    }
    } : {
    private = {
      netmask = 26
    }
  }
}

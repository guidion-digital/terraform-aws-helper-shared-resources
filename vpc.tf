locals {
  transit_gateway_enabled = var.vpc_config != null ? var.vpc_config.transit_gateway_enabled : false
  public_subnet_enabled   = var.vpc_config != null ? var.vpc_config.public_subnet_enabled   : false
  vpc_azs = var.vpc_config != null ? (
    var.vpc_config.az_count != null
      ? slice(data.aws_availability_zones.current.names, 0, var.vpc_config.az_count)
      : data.aws_availability_zones.current.names
  ) : []
}

data "aws_availability_zones" "current" {
  state = "available"
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

  subnets = merge(
    local.public_subnet_enabled ? {
      public = {
        netmask = 26
      }
      } : {
      private = {
        netmask = 26
      }
    },
    var.vpc_config.transit_gateway_enabled ? {
      transit_gateway = {
        netmask                                         = 28
        transit_gateway_default_route_table_association = true
        transit_gateway_default_route_table_propagation = true
        transit_gateway_appliance_mode_support          = "disable"
        transit_gateway_dns_support                     = "disable"
      }
    } : {}
  )
}

resource "aws_ec2_managed_prefix_list" "public_subnet_routes" {
  count = (
    var.vpc_config != null &&
    local.public_subnet_enabled &&
    local.transit_gateway_enabled
  ) ? 1 : 0

  name           = "${local.name}-public-subnet-routes"
  address_family = "IPv4"
  max_entries    = 10
  tags           = local.tags

  dynamic "entry" {
    for_each = var.public_subnet_prefix_list_entries
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

resource "aws_route" "public_subnet_prefix_list_routes" {
  for_each = (
    var.vpc_config != null &&
    local.public_subnet_enabled &&
    local.transit_gateway_enabled
  ) ? {
    for az in local.vpc_azs : az => az
  } : {}

  route_table_id             = one(module.vpc).rt_attributes_by_type_by_az.public[each.key].id
  destination_prefix_list_id = one(aws_ec2_managed_prefix_list.public_subnet_routes[*].id)
  transit_gateway_id         = one(data.aws_ec2_transit_gateway.this).id
}
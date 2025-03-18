module "vpc" {
  count = var.vpc_config != null ? 1 : 0

  source  = "aws-ia/vpc/aws"
  version = "4.3.1" # 4.3.2 has breaking change

  name               = local.name
  cidr_block         = var.vpc_config.vpc_cidr
  az_count           = var.vpc_config.az_count
  transit_gateway_id = data.aws_ec2_transit_gateway.this.id
  tags               = local.tags

  transit_gateway_routes = {
    private = "0.0.0.0/0"
  }

  subnets = {
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

  }
}

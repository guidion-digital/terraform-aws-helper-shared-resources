variable "application_name" { default = "test-app" }
variable "project" { default = "constr" }
variable "stage" { default = "development" }
variable "grafana_promtail_lambda_arn" { default = "arn:aws:lambda:eu-central-1:000000000000:function:grafana-promtail-lambda" }
# Left for edification, not used in tests
# variable "vpc_config" {
#   default = {
#     vpc_cidr                = "10.126.2.0/24"
#     transit_gateway_enabled = false
#   }
# }

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "shared_resources_x" {
  source = "../../"

  # Required variables
  application_name               = var.application_name
  namespace_supporting_resources = true
  stage                          = var.stage
  region                         = data.aws_region.current.name
  account_id                     = data.aws_caller_identity.current.account_id
  project                        = var.project
  grafana_promtail_lambda_arn    = var.grafana_promtail_lambda_arn

  # Optional variables
  # If provided, matching resources will be created.

  # Left for edification, not used in tests
  # Some resources such as RDS require the creation of a VPC, so vpc_config must also be passed if creating those or they will be skipped
  # vpc_config = var.vpc_config

  secrets = {
    "ihaveaterriblepassword" = {
      description             = "secret"
      recovery_window_in_days = 0

      # The map of principals passed here will be allowed to write values for
      # this secret
      allowed_update = {
        # Allow writes from the EC2 service in entirety
        "Service" = [
          "ec2.amazonaws.com"
        ],
        # Allow a role write operations. The role itself will _not_ need
        # any permissions to perform actions on this secret.
        "AWS" = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sso/Read-Only"
        ]
      }

      # Requires a real Lambda to run, which is outside the scope of this test
      # rotation_configuration = {
      #   lambda_arn          = "arn:aws:lambda:eu-central-1:123456789012:function:you-secret-rotator"
      #   schedule_expression = "rate(1 day)"
      # }
    }
  }

  ssm_parameters = {
    "test-param" = {
      description = "foo"
      value       = "bar"
    }
  }

  # Not supported by Localstack, but this is how it's used :)
  #   dynamodb_tables = {
  #     "test-table" = {
  #       attributes = [
  #         { name = "id", type = "N" },
  #         { name = "createdAt", type = "S" },
  #         { name = "gsi1", type = "N" }
  #       ],
  #       hash_key  = "id",
  #       range_key = "createdAt",
  #
  #       global_secondary_indexes = [
  #         {
  #           name               = "createdAtIndex",
  #           hash_key           = "createdAt",
  #           range_key          = "gsi1",
  #           non_key_attributes = ["id"],
  #           autoscaling = {
  #             read_max_capacity = 25
  #           }
  #         }
  #       ]
  #
  #       ttl_attribute_name = "expiresAt",
  #     }
  #   }

  sqs_queues = {
    "test-queue" = {
      # Override configuration here
      #
      # e.g.:
      # delay_seconds = 10
      #
      # This one will actually also create the necessary policy to enable rw on
      # the ARNs specified, and attach it
      # "readwrite_arns" = ["arn:aws:iam::107947530158:role/application/app-x"]
    }
  }

  # Not supported by Localstack, but this is how it's used :)
  # elasticache = {
  #   "memcached-01" = {
  #     application_name = var.application_name
  #     project          = var.project
  #     stage            = var.stage
  #     engine           = "memcached"
  #     engine_version   = "1.6.17"
  #     node_type        = "cache.t3.micro"
  #     az_mode          = "single-az"
  #   }
  # }

  # 30 minutes is too long for tests to run! but this is how it's used :)
  #   rds_instances = {
  #     "test-db" = {
  #       username        = "test"
  #       allow_vpc_cidr  = true
  #       multi_az        = false
  #       purge_on_delete = true
  #
  #       proxy_settings = {
  #         enabled = true
  #       }
  #
  #       replica_settings = {
  #         enabled = false
  #       }
  #     }
  #   }
}

output "secrets" {
  value = module.shared_resources_x.secrets
}

output "ssm_parameters" {
  value = module.shared_resources_x.ssm_parameters
}

output "dyanmodb_table_stream_arns" {
  value = module.shared_resources_x.dyanmodb_table_stream_arns
}

output "dynamodb" {
  value = module.shared_resources_x.dynamodb
}

output "sqs" {
  value = module.shared_resources_x.sqs
}

output "memcached" {
  value = module.shared_resources_x.memcached
}

output "rds" {
  value = module.shared_resources_x.rds
}

output "vpc" {
  value = module.shared_resources_x.vpc
}

output "rds_proxy_connect_role_arns" {
  value = module.shared_resources_x.rds_proxy_connect_role_arns
}

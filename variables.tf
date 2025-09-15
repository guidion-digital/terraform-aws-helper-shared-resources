variable "project" {
  description = "Project (team) responsible for these resources"
}

variable "application_name" {
  description = "Name of the application these resources are tied to"
}

variable "namespace" {
  description = "Used for naming and tagging. Overrides var.application_name for namespacing if supplied"
  type        = string
  default     = null
}

locals {
  namespace = var.namespace != null ? var.namespace : var.application_name != null ? "/applications/${var.application_name}" : ""
}

variable "stage" {
  description = "Stage of the application these resources are tied to"
}

variable "account_id" {
  description = "Account ID of the application these resources are tied to"
}

variable "region" {
  description = "Region of the application these resources are tied to"
}

variable "vpc_config" {
  description = "VPC will be created for this application if supplied"

  type = object({
    vpc_cidr                = string,
    az_count                = optional(number, 3),
    transit_gateway_enabled = optional(bool, true)
  })

  default = null
}

variable "grafana_promtail_lambda_arn" {
  description = "ARN of the Grafana Promtail Lambda function"
}

# For supporting resources module
variable "sqs_queues" {
  description = "SQS queues will be created if values are supplied for this"

  type = map(object({
    content_based_deduplication     = optional(bool, null),
    deduplication_scope             = optional(string, null),
    delay_seconds                   = optional(number, null),
    dlq_content_based_deduplication = optional(bool, null),
    dlq_deduplication_scope         = optional(string, null),
    dlq_delay_seconds               = optional(number, null),
    dlq_message_retention_seconds   = optional(number, null),
    dlq_receive_wait_time_seconds   = optional(number, null),
    dlq_visibility_timeout_seconds  = optional(number, null),
    fifo_queue                      = optional(bool, false),
    fifo_throughput_limit           = optional(string, null),
    max_message_size                = optional(number, null),
    message_retention_seconds       = optional(number, null),
    receive_wait_time_seconds       = optional(number, null),
    visibility_timeout_seconds      = optional(number, null),
    readwrite_arns                  = optional(list(string), [])
    read_arns                       = optional(list(string), []),
    redrive_policy = optional(object({
      maxReceiveCount = optional(number, 10)
      }), {
      maxReceiveCount = 10
    })
  }))

  default = {}
}

variable "namespace_supporting_resources" {
  description = "Whether to prepend var.application_name to supporting resources like var.dynamodb_tables"
  type        = bool
  default     = true
}

variable "dynamodb_tables" {
  description = "DynamoDB tables will be created if values are supplied for this"

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html
  type = map(object({
    attributes = list(map(string)),
    hash_key   = string,
    range_key  = optional(string),

    billing_mode                          = optional(string, "PROVISIONED"),
    read_capacity                         = optional(number, 5),
    write_capacity                        = optional(number, 5),
    autoscaling_enabled                   = optional(bool, true),
    ignore_changes_global_secondary_index = optional(bool, false),
    ttl_attribute_name                    = optional(string, ""),
    stream_view_type                      = optional(string, "NEW_IMAGE"),
    point_in_time_recovery_enabled        = optional(bool, false),
    timeouts                              = optional(map(string), { "create" : "10m", "delete" : "10m", "update" : "60m" }),

    autoscaling_read_scale_in_cooldown  = optional(number, 50),
    autoscaling_read_scale_out_cooldown = optional(number, 40),
    autoscaling_read_target_value       = optional(number, 45),
    autoscaling_read_max_capacity       = optional(number, 10),

    autoscaling_write_scale_in_cooldown  = optional(number, 50),
    autoscaling_write_scale_out_cooldown = optional(number, 40),
    autoscaling_write_target_value       = optional(number, 45),
    autoscaling_write_max_capacity       = optional(number, 10),

    global_secondary_indexes : optional(list(
      object({
        name               = string,
        hash_key           = string,
        range_key          = string,
        projection_type    = optional(string, "INCLUDE"),
        non_key_attributes = list(string),
        write_capacity     = optional(number, 10)
        read_capacity      = optional(number, 10)

        autoscaling = optional(object({
          read_max_capacity  = optional(number, 30),
          read_min_capacity  = optional(number, 10),
          write_max_capacity = optional(number, 30),
          write_min_capacity = optional(number, 10)
        }), null)
      })),
    [])
  }))

  default = {}
}

variable "secrets" {
  description = "Object of secrets, mapped to their settings"

  type = map(object({
    description                    = optional(string, null)
    kms_key_id                     = optional(string, null)
    recovery_window_in_days        = optional(number, 7)
    force_overwrite_replica_secret = optional(bool, false)

    allowed_update = optional(map(list(string)), null)

    rotation_configuration = optional(object({
      lambda_arn          = string
      schedule_expression = string
    }), null)
  }))

  default = {}
}

variable "elasticache" {
  description = "Map of Elasticache clusters to create"

  type = map(object({
    name                       = optional(string, null)
    project                    = string
    application_name           = string
    stage                      = string
    engine                     = optional(string, "memcached")
    engine_version             = optional(string, "1.6.17")
    node_type                  = optional(string, "cache.t4g.micro")
    apply_immediately          = optional(bool, false)
    transit_encryption_enabled = optional(bool, true)
    auto_minor_version_upgrade = optional(bool, null)
    maintenance_window         = optional(string, "sun:05:00-sun:09:00")
    parameters = optional(list(object({
      name  = string
      value = string
    })), [])
    ip_discovery                 = optional(string, "ipv4")
    network_type                 = optional(string, "ipv4")
    port                         = optional(number, null)
    notification_topic_arn       = optional(string, null)
    az_mode                      = optional(string, "single-az")
    availability_zone            = optional(string, null)
    preferred_availability_zones = optional(list(string), null)
    num_cache_nodes              = optional(number, 1)
    vpc_id                       = optional(string, null)
    subnet_ids                   = optional(list(string), null)
    security_group_rules = optional(map(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    })), {})
    security_group_ids      = optional(list(string), [])
    allowed_cidrs           = optional(list(string), null)
    allowed_security_groups = optional(list(string), [])
  }))

  default = {}
}

variable "rds_instances" {
  description = "Map of RDS instances to create"

  type = map(object({
    allocated_storage           = optional(number, 20)
    max_allocated_storage       = optional(number, 120)
    storage_encrypted           = optional(bool, true)
    maintenance_window          = optional(string, "sun:03:34-sun:04:04")
    backup_window               = optional(string, "04:18-04:48")
    backup_retention_period     = optional(number, 7)
    deletion_protection         = optional(bool, true)
    delete_automated_backups    = optional(bool, true)
    skip_final_snapshot         = optional(bool, false)
    purge_on_delete             = optional(bool, false)
    apply_immediately           = optional(bool, true)
    auto_minor_version_upgrade  = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)
    availability_zone           = optional(string, null)
    multi_az                    = optional(bool, true)
    blue_green_update           = optional(map(string), {})
    ca_cert_identifier          = optional(string, "rds-ca-rsa2048-g1")

    options = optional(
      list(object({
        option_name = string
        option_settings = list(object({
          name  = string
          value = string
        }))
    })), [])

    allowed_cidrs             = optional(list(string), [])
    allow_vpc_cidr            = optional(bool, false)
    vpc_security_group_ids    = optional(list(string), [])
    create_db_subnet_group    = optional(bool, true)
    create_db_parameter_group = optional(bool, true)
    create_monitoring_role    = optional(bool, true)

    username                    = string
    password                    = optional(string, null)
    password_rotation_days      = optional(number, null)
    password_rotation_duration  = optional(string, "3h")
    rotate_password_immediately = optional(bool, false)

    rotator_lambda_role_name              = optional(string, null)
    password_rotation_schedule_expression = optional(string, null)

    build_lambdas_in_docker             = optional(bool, false)
    iam_database_authentication_enabled = optional(bool, false)
    password_kms_key_id                 = optional(string, null)

    db_name   = optional(string, null)
    create_db = optional(bool, true)

    enabled_cloudwatch_logs_exports = optional(list(string), [])
    engine                          = optional(string, "mysql")
    engine_version                  = optional(string, null)
    family                          = optional(string, "mysql8.0")
    major_engine_version            = optional(string, "8.0")

    port           = optional(number, 3306)
    instance_class = optional(string, "db.t3.micro")

    copy_tags_to_snapshot = optional(bool, true)
    timeouts_create       = optional(string, "40m")
    timeouts_update       = optional(string, "80m")
    timeouts_delete       = optional(string, "40m")
    storage_type          = optional(string, "gp2")
    storage_throughput    = optional(number, null)

    iops                     = optional(number, null)
    kms_key_id               = optional(string, null)
    engine_lifecycle_support = optional(bool, null)

    performance_insights_enabled          = optional(bool, false)
    performance_insights_retention_period = optional(number, 7)

    network_type = optional(string, null)

    proxy_settings = optional(object({
      enabled                      = optional(bool, false)
      require_tls                  = optional(bool, true)
      idle_client_timeout          = optional(number, 1800)
      role_arn                     = optional(string, "")
      connection_borrow_timeout    = optional(number, null)
      init_query                   = optional(string, "")
      max_connections_percent      = optional(number, 90)
      max_idle_connections_percent = optional(number, 10)
      session_pinning_filters      = optional(list(string), [])
      iam_auth                     = optional(string, "DISABLED")
    }))

    replica_settings = optional(object({
      enabled                               = optional(bool, false)
      instance_class                        = optional(string)
      availability_zone                     = optional(string)
      publicly_accessible                   = optional(bool)
      vpc_security_group_ids                = optional(list(string))
      allow_major_version_upgrade           = optional(bool)
      auto_minor_version_upgrade            = optional(bool)
      maintenance_window                    = optional(string)
      max_allocated_storage                 = optional(number)
      storage_throughput                    = optional(number)
      performance_insights_enabled          = optional(bool)
      performance_insights_retention_period = optional(number)
      apply_immediately                     = optional(bool)
      ca_cert_identifier                    = optional(string)
      network_type                          = optional(string)
      create_db_subnet_group                = optional(bool, true)
      subnet_ids                            = optional(list(string))
      enabled_cloudwatch_logs_exports       = optional(list(string))
      timeouts_create                       = optional(string)
      timeouts_delete                       = optional(string)
      timeouts_update                       = optional(string)
      create_db_parameter_group             = optional(bool, false)
      options = optional(list(object({
        option_name = string
        option_settings = list(object({
          name  = string
          value = string
        }))
      })))
    }))
  }))

  default = {}
}

variable "ssm_parameters" {
  description = "Map of SSM parameters, and their configuration"

  type = map(object({
    description    = optional(string, "")
    type           = optional(string, null)
    value          = optional(string, null)
    insecure_value = optional(string, null)
    ignore_changes = optional(bool, false)
    key_id         = optional(string, null)
    tier           = optional(string, "standard")
    tags           = optional(map(string), {})
  }))

  default = {}
}

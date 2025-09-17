resource "aws_iam_role" "rds_proxy" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  name        = "${var.application_name}-${each.key}-rds-proxy"
  description = "Role needed by RDS Proxy for ${var.application_name}-${each.key}"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "RDSAssume",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "rds.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "rds_proxy" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  statement {
    sid    = "DecryptRDSSecrets"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:*:*:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "ListRDSSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
      "secretsmanager:GetRandomPassword"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GetRDSSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${local.namespace}/${var.application_name}-${each.key}-rds-password-*"
    ]
  }
}

resource "aws_iam_policy" "rds_proxy" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  name        = "${var.application_name}-${each.key}-rds-proxy"
  description = "Policy for RDS Proxy role"
  policy      = data.aws_iam_policy_document.rds_proxy[each.key].json
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  role       = aws_iam_role.rds_proxy[each.key].name
  policy_arn = aws_iam_policy.rds_proxy[each.key].arn
}

module "rds" {
  source  = "guidion-digital/helper-rds/aws"
  version = "~> 1.1"

  depends_on = [module.vpc]
  for_each   = var.vpc_config != null ? var.rds_instances : {}

  application_name            = var.application_name
  project                     = var.project
  stage                       = var.stage
  grafana_promtail_lambda_arn = var.grafana_promtail_lambda_arn

  identifier = "${var.application_name}-${each.key}"
  db_name    = each.value.db_name
  create_db  = each.value.create_db

  username                              = each.value.username
  password                              = each.value.password
  password_rotation_days                = each.value.password_rotation_days
  password_rotation_duration            = each.value.password_rotation_duration
  rotate_password_immediately           = each.value.rotate_password_immediately
  rotator_lambda_role_name              = each.value.rotator_lambda_role_name
  password_rotation_schedule_expression = each.value.password_rotation_schedule_expression
  password_kms_key_id                   = each.value.password_kms_key_id

  instance_class        = each.value.instance_class
  port                  = each.value.port
  engine                = each.value.engine
  engine_version        = each.value.engine_version
  family                = each.value.family
  major_engine_version  = each.value.major_engine_version
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_encrypted     = each.value.storage_encrypted

  deletion_protection      = each.value.deletion_protection
  delete_automated_backups = each.value.delete_automated_backups
  skip_final_snapshot      = each.value.skip_final_snapshot
  purge_on_delete          = each.value.purge_on_delete
  ca_cert_identifier       = each.value.ca_cert_identifier

  replica_settings            = each.value.replica_settings
  maintenance_window          = each.value.maintenance_window
  backup_window               = each.value.backup_window
  backup_retention_period     = each.value.backup_retention_period
  apply_immediately           = each.value.apply_immediately
  auto_minor_version_upgrade  = each.value.auto_minor_version_upgrade
  allow_major_version_upgrade = each.value.allow_major_version_upgrade
  blue_green_update           = each.value.blue_green_update
  options                     = each.value.options

  availability_zone         = each.value.availability_zone
  multi_az                  = each.value.multi_az
  allowed_cidrs             = each.value.allowed_cidrs
  allow_vpc_cidr            = each.value.allow_vpc_cidr
  vpc_id                    = one(module.vpc).vpc_attributes.id
  vpc_cidr                  = one(module.vpc).vpc_attributes.cidr_block
  vpc_security_group_ids    = each.value.vpc_security_group_ids
  subnet_ids                = [for _, value in one(module.vpc).private_subnet_attributes_by_az : value.id]
  create_db_subnet_group    = each.value.create_db_subnet_group
  create_db_parameter_group = each.value.create_db_parameter_group

  create_monitoring_role          = each.value.create_monitoring_role
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports

  build_lambdas_in_docker             = each.value.build_lambdas_in_docker
  iam_database_authentication_enabled = each.value.iam_database_authentication_enabled

  copy_tags_to_snapshot = each.value.copy_tags_to_snapshot
  timeouts_create       = each.value.timeouts_create
  timeouts_update       = each.value.timeouts_update
  timeouts_delete       = each.value.timeouts_delete
  storage_type          = each.value.storage_type
  storage_throughput    = each.value.storage_throughput

  iops                     = each.value.iops
  kms_key_id               = each.value.kms_key_id
  engine_lifecycle_support = each.value.engine_lifecycle_support

  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_retention_period = each.value.performance_insights_retention_period

  network_type = each.value.network_type

  proxy_settings = each.value.proxy_settings != null ? merge(each.value.proxy_settings, {
    role_arn = aws_iam_role.rds_proxy[each.key].arn
    iam_auth = "REQUIRED"
  }) : null
}

resource "aws_iam_role" "rds_proxy_connect" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  name        = "${var.application_name}-${each.key}-rds-connect"
  description = "Role needed to connect to the ${var.application_name}-${each.key} RDS DB"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "RDSAssume",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "rds.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "rds_proxy_connect" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  statement {
    sid = "rds0c"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      module.rds[each.key].mysql_proxy_user_arn
    ]
  }

  statement {
    sid = "secretsreadrds"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      module.rds[each.key].rds_password_secret_arn
    ]
  }
}

resource "aws_iam_policy" "rds_proxy_connect" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  name        = "${var.application_name}-${each.key}-rds-connect"
  description = "Permissions necessary to connect to ${var.application_name}-${each.key} RDS DB"
  policy      = data.aws_iam_policy_document.rds_proxy_connect[each.key].json
}

resource "aws_iam_role_policy_attachment" "rds_proxy_connect" {
  for_each = var.vpc_config != null ? var.rds_instances : {}

  role       = aws_iam_role.rds_proxy_connect[each.key].name
  policy_arn = aws_iam_policy.rds_proxy_connect[each.key].arn
}

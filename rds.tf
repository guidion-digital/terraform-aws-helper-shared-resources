resource "aws_iam_role" "rds_proxy" {
  name        = "homeapp-backend-rds-proxy-new"
  description = "Role needed by RDS Proxy for homeapp-backend"

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
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:applications/${var.application_name}/${var.application_name}-rds-password-*"
    ]
  }
}

resource "aws_iam_policy" "rds_proxy" {
  name        = "homeapp-backend-rds-proxy-new"
  description = "Policy for RDS Proxy role"
  policy      = data.aws_iam_policy_document.rds_proxy.json
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = aws_iam_policy.rds_proxy.arn
}

module "rds" {
  source  = "guidion-digital/helper-rds/aws"
  version = "~> 0.0"

  depends_on = [module.vpc]
  count      = var.rds != null && var.vpc_config != null ? 1 : 0

  application_name            = var.application_name
  project                     = var.project
  stage                       = var.stage
  grafana_promtail_lambda_arn = var.grafana_promtail_lambda_arn

  identifier = "${var.application_name}-${var.rds.identifier}"
  db_name    = var.rds.db_name
  create_db  = var.rds.create_db

  username                              = var.rds.username
  password                              = var.rds.password
  password_rotation_days                = var.rds.password_rotation_days
  password_rotation_duration            = var.rds.password_rotation_duration
  rotate_password_immediately           = var.rds.rotate_password_immediately
  rotator_lambda_role_name              = var.rds.rotator_lambda_role_name
  password_rotation_schedule_expression = var.rds.password_rotation_schedule_expression
  password_kms_key_id                   = var.rds.password_kms_key_id

  instance_class        = var.rds.instance_class
  port                  = var.rds.port
  engine                = var.rds.engine
  engine_version        = var.rds.engine_version
  family                = var.rds.family
  major_engine_version  = var.rds.major_engine_version
  allocated_storage     = var.rds.allocated_storage
  max_allocated_storage = var.rds.max_allocated_storage
  storage_encrypted     = var.rds.storage_encrypted


  deletion_protection      = var.rds.deletion_protection
  delete_automated_backups = var.rds.delete_automated_backups
  skip_final_snapshot      = var.rds.skip_final_snapshot
  purge_on_delete          = var.rds.purge_on_delete
  ca_cert_identifier       = var.rds.ca_cert_identifier

  replica_settings                   = var.rds.replica_settings
  allow_major_engine_version_upgrade = var.rds.allow_major_engine_version_upgrade
  maintenance_window                 = var.rds.maintenance_window
  backup_window                      = var.rds.backup_window
  backup_retention_period            = var.rds.backup_retention_period
  apply_immediately                  = var.rds.apply_immediately
  auto_minor_version_upgrade         = var.rds.auto_minor_version_upgrade
  blue_green_update                  = var.rds.blue_green_update
  options                            = var.rds.options

  availability_zone         = var.rds.availability_zone
  multi_az                  = var.rds.multi_az
  allowed_cidrs             = var.rds.allowed_cidrs
  allow_vpc_cidr            = var.rds.allow_vpc_cidr
  vpc_id                    = try(module.vpc[0].vpc_attributes.id, null)
  vpc_cidr                  = var.vpc_config.vpc_cidr
  vpc_security_group_ids    = var.rds.vpc_security_group_ids
  subnet_ids                = [for _, value in module.vpc[0].private_subnet_attributes_by_az : value.id]
  create_db_subnet_group    = var.rds.create_db_subnet_group
  create_db_parameter_group = var.rds.create_db_parameter_group

  create_monitoring_role          = var.rds.create_monitoring_role
  enabled_cloudwatch_logs_exports = var.rds.enabled_cloudwatch_logs_exports

  build_lambdas_in_docker             = var.rds.build_lambdas_in_docker
  iam_database_authentication_enabled = var.rds.iam_database_authentication_enabled

  copy_tags_to_snapshot = var.rds.copy_tags_to_snapshot
  timeouts_create       = var.rds.timeouts_create
  timeouts_update       = var.rds.timeouts_update
  timeouts_delete       = var.rds.timeouts_delete
  storage_type          = var.rds.storage_type
  storage_throughput    = var.rds.storage_throughput

  iops                     = var.rds.iops
  kms_key_id               = var.rds.kms_key_id
  engine_lifecycle_support = var.rds.engine_lifecycle_support

  performance_insights_enabled          = var.rds.performance_insights_enabled
  performance_insights_retention_period = var.rds.performance_insights_retention_period

  network_type = var.rds.network_type

  proxy_settings = var.rds.proxy_settings != null ? merge(var.rds.proxy_settings, {
    role_arn = aws_iam_role.rds_proxy.arn
    iam_auth = "REQUIRED"
  }) : null
}

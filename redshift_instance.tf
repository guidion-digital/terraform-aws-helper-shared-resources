resource "aws_eip" "redshift_public_ip" {
  domain = "vpc"
}

module "redshift" {
  source  = "terraform-aws-modules/redshift/aws"
  version = "7.1.0"

  depends_on = [module.vpc]
  for_each   = var.vpc_config != null ? var.redshift_instances : {}

  cluster_identifier = lower("${var.application_name}-${each.key}")

  database_name   = each.value.database_name
  master_username = each.value.master_username

  manage_master_password                            = each.value.manage_master_password
  manage_master_password_rotation                   = each.value.manage_master_password_rotation
  master_password_wo                                = each.value.master_password_wo
  master_password_wo_version                        = each.value.master_password_wo_version
  master_password_secret_kms_key_id                 = each.value.master_password_secret_kms_key_id
  master_password_rotate_immediately                = each.value.master_password_rotate_immediately
  master_password_rotation_automatically_after_days = each.value.master_password_rotation_automatically_after_days
  master_password_rotation_duration                 = each.value.master_password_rotation_duration
  master_password_rotation_schedule_expression      = each.value.master_password_rotation_schedule_expression

  allow_version_upgrade = each.value.allow_version_upgrade
  apply_immediately     = each.value.apply_immediately
  cluster_version       = each.value.cluster_version

  node_type                            = each.value.node_type
  number_of_nodes                      = each.value.number_of_nodes
  multi_az                             = each.value.multi_az
  publicly_accessible                  = each.value.publicly_accessible
  enhanced_vpc_routing                 = each.value.enhanced_vpc_routing
  availability_zone                    = each.value.availability_zone
  availability_zone_relocation_enabled = each.value.availability_zone_relocation_enabled

  port                         = each.value.port
  preferred_maintenance_window = each.value.preferred_maintenance_window

  automated_snapshot_retention_period = each.value.automated_snapshot_retention_period
  manual_snapshot_retention_period    = each.value.manual_snapshot_retention_period
  skip_final_snapshot                 = each.value.skip_final_snapshot
  final_snapshot_identifier           = each.value.final_snapshot_identifier
  snapshot_arn                        = each.value.snapshot_arn
  owner_account                       = each.value.owner_account

  encrypted   = each.value.encrypted
  kms_key_arn = each.value.kms_key_arn
  tags        = merge(local.tags, each.value.tags)

  vpc_id = one(module.vpc).vpc_attributes.id

  create_security_group  = false
  vpc_security_group_ids = each.value.vpc_security_group_ids

  create_subnet_group      = each.value.create_subnet_group
  subnet_ids               = [for _, value in one(module.vpc).public_subnet_attributes_by_az : value.id]
  subnet_group_name        = each.value.subnet_group_name
  subnet_group_description = each.value.subnet_group_description
  subnet_group_tags        = merge(local.tags, each.value.subnet_group_tags)

  create_parameter_group      = each.value.create_parameter_group
  parameter_group_name        = each.value.parameter_group_name
  parameter_group_description = each.value.parameter_group_description
  parameter_group_family      = each.value.parameter_group_family
  parameter_group_parameters  = each.value.parameter_group_parameters
  parameter_group_tags        = merge(local.tags, each.value.parameter_group_tags)

  create_cloudwatch_log_group            = each.value.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = each.value.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = each.value.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_skip_destroy      = each.value.cloudwatch_log_group_skip_destroy
  cloudwatch_log_group_tags              = merge(local.tags, each.value.cloudwatch_log_group_tags)

  logging           = each.value.logging
  snapshot_copy     = each.value.snapshot_copy
  snapshot_schedule = each.value.snapshot_schedule

  endpoint_access         = each.value.endpoint_access
  authentication_profiles = each.value.authentication_profiles
  usage_limits            = each.value.usage_limits

  create_scheduled_action_iam_role = each.value.create_scheduled_action_iam_role
  scheduled_actions                = each.value.scheduled_actions
  iam_role_arns                    = each.value.iam_role_arns
  default_iam_role_arn             = each.value.default_iam_role_arn
  iam_role_name                    = each.value.iam_role_name
  iam_role_description             = each.value.iam_role_description
  iam_role_path                    = each.value.iam_role_path
  iam_role_permissions_boundary    = each.value.iam_role_permissions_boundary
  iam_role_tags                    = merge(local.tags, each.value.iam_role_tags)
  iam_role_use_name_prefix         = each.value.iam_role_use_name_prefix

  cluster_timeouts = each.value.cluster_timeouts
}

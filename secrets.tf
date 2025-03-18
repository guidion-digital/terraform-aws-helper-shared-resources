locals {
  secrets = { for this_secret, these_values in var.secrets : this_secret => {
    description                    = these_values.description
    kms_key_id                     = these_values.kms_key_id
    recovery_window_in_days        = these_values.recovery_window_in_days
    force_overwrite_replica_secret = these_values.force_overwrite_replica_secret
    rotation_configuration         = these_values.rotation_configuration

    policy = these_values.allowed_update != null ? jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Principal" : these_values.allowed_update,
            "Action" : [
              "secretsmanager:DescribeSecret",
              "secretsmanager:PutSecretValue",
              "secretsmanager:ListSecretVersionIds"
            ],
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Principal" : these_values.allowed_update,
            "Action" : [
              "secretsmanager:GetRandomPassword",
              "secretsmanager:ListSecrets",
              "secretsmanager:BatchGetSecretValue"
            ],
            "Resource" : "*"
          }
        ]
    }) : null
    }
  }
}

module "secrets" {
  for_each = local.secrets

  source  = "guidion-digital/helper-secrets/aws"
  version = "~> 1.0"

  secrets = {
    "applications/${var.application_name}/${each.key}" = {
      description                    = each.value.description
      kms_key_id                     = each.value.kms_key_id
      policy                         = each.value.policy
      recovery_window_in_days        = each.value.recovery_window_in_days
      force_overwrite_replica_secret = each.value.force_overwrite_replica_secret
      rotation_configuration         = each.value.rotation_configuration
    }
  }

  tags = module.these_tags.tags
}

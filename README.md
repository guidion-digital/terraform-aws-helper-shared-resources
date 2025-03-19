Part of the [Terrappy framework](https://github.com/guidion-digital/terrappy).

---

# Usage

See [examples folder](./examples).

# Rationale

Creates:

- Elasticache (Memcached)
- ASM Secrets
- DynamoDB
- RDS (MySQL)
- SQS
- SSM Parameters

for use with the [workspaces](https://github.com/guidion-digital/terraform-tfe-infra-workspaces/blob/acc/README.md) module.

Resources which can be placed in a VPC will need either `vpc_id` to be set, or `vpc_config` to be configured. If neither are given, they will fail to be created.

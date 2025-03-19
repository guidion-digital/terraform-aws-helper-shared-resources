module "these_tags" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace = var.project
  name      = local.name
  delimiter = "-"

  tags = {
    "Terraform"       = "true",
    "Module"          = "helper-shared-resources",
    "project"         = var.project,
    "application"     = var.application_name,
    "stage"           = var.stage,
    "shared_resource" = "true"
  }
}

locals {
  # Remove the 'Name' tag, because it's confusing when the resource name isn't
  # actually this
  tags = { for k, v in module.these_tags.tags : k => v if k != "Name" }

  name = var.application_name
}

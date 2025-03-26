module "ssm_parameters" {
  source  = "guidion-digital/helper-ssm-parameters/aws"
  version = "~> 0.1.0"

  project          = var.project
  application_name = var.application_name
  stage            = var.stage

  parameters = var.ssm_parameters
}

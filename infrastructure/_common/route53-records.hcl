terraform {
  source = "git::ssh://yurii-furko@bitbucket.org/yuriyfRnD/tf-aws-route53-records.git?ref=v1.0.0"
}

locals {
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  project_name = local.environment_vars.locals.project_name
  environment  = local.environment_vars.locals.environment
  domain_name  = local.environment_vars.locals.domain_name
  profile      = local.account_vars.locals.profile
  account_id   = local.account_vars.locals.account_id
  region       = local.region_vars.locals.region
}

inputs = {}

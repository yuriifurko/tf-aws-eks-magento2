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

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
  profile = "${local.profile}"
}
EOF
}

remote_state {
  backend = "s3"

  config = {
    encrypt        = true
    bucket         = "${local.account_id}-terragrunt-state-${local.project_name}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    profile        = local.profile
    dynamodb_table = "terraform-locks"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals,
)
terraform {
  source = "git::ssh://yurii-furko@bitbucket.org/yuriyfRnD/tf-aws-eks-cluster.git?ref=v1.0.1"
}

locals {
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  project_name = local.environment_vars.locals.project_name
  environment  = local.environment_vars.locals.environment
  profile      = local.account_vars.locals.profile
  account_id   = local.account_vars.locals.account_id
  region       = local.region_vars.locals.region
}

inputs = {
  eks_version        = "1.26"
  eks_addons_enabled = false

  eks_service_ipv4_cidr = "172.20.0.0/16"

  eks_encryption_config_enabled = false

  endpoint_public_access  = true
  endpoint_private_access = false

  public_access_cidrs = [
    "0.0.0.0/0",
  ]

  tags = {
    "kubernetes.io/cluster/${local.project_name}-${local.environment}" = "owned"
  }
}
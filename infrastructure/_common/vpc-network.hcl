terraform {
  source = "git::ssh://yurii-furko@bitbucket.org/yuriyfRnD/tf-aws-vpc-network.git?ref=v1.0.0"
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
  nat_gateway_enabled = true
  single_nat_gateway  = true

  vpc_flow_logs_enabled         = false
  vpc_flow_log_destination_type = "s3"

  s3_endpoint_enabled = true
  private_dns_enabled = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "${local.project_name}-${local.environment}"
  }

  tags = {
    "kubernetes.io/cluster/${local.project_name}-${local.environment}" = "owned"
    "kubernetes.io/cluster/${local.project_name}-${local.environment}" = "shared"
  }
}
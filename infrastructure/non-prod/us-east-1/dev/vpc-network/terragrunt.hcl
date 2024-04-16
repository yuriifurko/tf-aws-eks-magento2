include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "vpc_network" {
  path   = "${dirname(find_in_parent_folders())}/_common/vpc-network.hcl"
  expose = true
}

dependency "datasources" {
  config_path = "${get_terragrunt_dir()}/../data-sources"
  mock_outputs = {
    availability_zones = [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c"
    ]
  }
}

inputs = {
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(dependency.datasources.outputs.availability_zones, 0, 3)
  public_subnets     = [for k, v in slice(dependency.datasources.outputs.availability_zones, 0, 3) : cidrsubnet("10.0.0.0/16", 8, k + 48)]
  private_subnets    = [for k, v in slice(dependency.datasources.outputs.availability_zones, 0, 3) : cidrsubnet("10.0.0.0/16", 8, k)]
}
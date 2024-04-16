include "root" {
  path   = find_in_parent_folders()
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

dependency "eks_cluster" {
  config_path = "${get_terragrunt_dir()}/../eks-cluster"
  mock_outputs = {
    eks_cluster_name     = "${include.root.locals.project_name}-${include.root.locals.environment}"
    eks_cluster_endpoint = "https://000000000000.gr7.${include.root.locals.region}.eks.amazonaws.com"

    eks_cluster_self_managed_worker_node_iam_role_arn = "arn:aws:iam::000000000000:role/${include.root.locals.project_name}-${include.root.locals.environment}"
  }
}

dependency "vpc_cni" {
  config_path = "${get_terragrunt_dir()}/../eks-cluster-irsa/vpc-cni"

  mock_outputs = {
    iam_role_arn = "arn:aws:iam::${include.root.locals.account_id}:role/vpc-cni"
  }
}

include "eks_cluser_addons" {
  path   = "${dirname(find_in_parent_folders())}/_common/eks-cluster-addons.hcl"
  expose = false
}

inputs = {
  eks_addons = {
    "kube-proxy" = {
      enabled       = true
      addon_name    = "kube-proxy"
      addon_version = "v1.29.1-eksbuild.2"
    },
    "coredns" = {
      enabled       = true
      addon_name    = "coredns"
      addon_version = "v1.11.1-eksbuild.6"
    },
    "vpc-cni" = {
      enabled       = false
      addon_name    = "vpc-cni"
      addon_version = "v1.18.0-eksbuild.1"
      role_arn      = dependency.vpc_cni.outputs.iam_role_arn

      configs = jsonencode({
        env = {
          # Reference docs
          # https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          # https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
}
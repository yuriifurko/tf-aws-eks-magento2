include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "datasources" {
  config_path = "${get_terragrunt_dir()}/../../data-sources"
  mock_outputs = {
    availability_zones = [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c"
    ]
  }
}

dependency "eks_cluster" {
  config_path = "${get_terragrunt_dir()}/../../eks-cluster"
  mock_outputs = {
    eks_cluster_name     = "${include.root.locals.project_name}-${include.root.locals.environment}"
    eks_cluster_endpoint = "https://000000000000.gr7.${include.root.locals.region}.eks.amazonaws.com"

    eks_cluster_identity_oidc_issuer_arn = "arn:aws:iam::000000000000:role/${include.root.locals.project_name}-${include.root.locals.environment}"
  }
}

include "eks_cluser_irsa" {
  path   = "${dirname(find_in_parent_folders())}/_common/eks-cluster-irsa.hcl"
  expose = false
}

inputs = {
  role_name_prefix      = "vpc-cni-irsa"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = dependency.eks_cluster.outputs.eks_cluster_identity_oidc_issuer_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
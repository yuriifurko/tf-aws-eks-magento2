include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "karpenter" {
  path   = "${dirname(find_in_parent_folders())}/_common/karpenter.hcl"
  expose = false
}

dependency "eks_cluster" {
  config_path = "${get_terragrunt_dir()}/../../eks-cluster"
  mock_outputs = {
    eks_cluster_name     = "${include.root.locals.project_name}-${include.root.locals.environment}"
    eks_cluster_endpoint = "https://000000000000.gr7.${include.root.locals.region}.eks.amazonaws.com"

    eks_cluster_identity_oidc_issuer     = "oidc.eks.${include.root.locals.region}.amazonaws.com/id/000000000000"
    eks_cluster_identity_oidc_issuer_arn = "arn:aws:iam::${include.root.locals.account_id}:oidc-provider/oidc.eks.${include.root.locals.region}.amazonaws.com/id/000000000000"
  }
}

generate "eks_providers" {
  path      = "eks_providers.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
    data "aws_eks_cluster" "eks_cluster" {
      name = "${dependency.eks_cluster.outputs.eks_cluster_name}"
    }

    data "aws_eks_cluster_auth" "eks_cluster" {
      name = "${dependency.eks_cluster.outputs.eks_cluster_name}"
    }

    provider "kubernetes" {
      host                   = data.aws_eks_cluster.eks_cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.eks_cluster.token
    }

    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.eks_cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.eks_cluster.token
      }
    }
EOF
}

inputs = {
  eks_cluster_name     = dependency.eks_cluster.outputs.eks_cluster_name
  eks_cluster_endpoint = dependency.eks_cluster.outputs.eks_cluster_endpoint

  eks_cluster_identity_oidc_issuer     = dependency.eks_cluster.outputs.eks_cluster_identity_oidc_issuer
  eks_cluster_identity_oidc_issuer_arn = dependency.eks_cluster.outputs.eks_cluster_identity_oidc_issuer_arn

  values = concat([
    yamlencode({
    })
  ])
}
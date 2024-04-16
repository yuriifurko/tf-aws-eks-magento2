include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "nginx_ingress_controller" {
  path   = "${dirname(find_in_parent_folders())}/_common/nginx-ingress-controller.hcl"
  expose = true
}

dependency "datasources" {
  config_path = "${get_terragrunt_dir()}/../../data-sources"
  mock_outputs = {
    region = "us-east-0"
    availability_zones = [
      "us-east1-a",
      "us-east1-b",
      "us-east1-c"
    ]
    account_id = "000000000000"
  }
}

dependency "vpc_network" {
  config_path = "${get_terragrunt_dir()}/../../vpc-network"

  mock_outputs = {
    vpc_id         = "vpc-00000000"
    vpc_cidr_block = "0.0.0.0/0"
    vpc_public_subnets_id = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]

    vpc_private_subnets_id = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
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
  cert_manager_acme_email = "yurii.furko@gmail.com"

  # required CRDs from kube-prometheus stack helm chart
  monitoring_enabled = false
  alerts_enabled     = false

  lb_nginx_ingress_enabled = false
  lb_subnets_ids           = dependency.vpc_network.outputs.vpc_public_subnets_id
  lb_certeficate_arn       = "arn:aws:acm:${dependency.datasources.outputs.region}:${dependency.datasources.outputs.account_id}:certificate/715ffc27-2870-4ac7-843b-826819fb6d31"

  values = concat(
    [
      yamlencode({
        controller = {
          service = {
            type = "ClusterIP"
          }
        }
      })
    ]
  )
}
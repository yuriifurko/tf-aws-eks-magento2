include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "jenkins" {
  path   = "${dirname(find_in_parent_folders())}/_common/jenkins.hcl"
  expose = true
}

dependency "eks_cluster" {
  config_path = "${get_terragrunt_dir()}/../../eks-cluster"
  mock_outputs = {
    eks_cluster_name     = "${include.root.locals.project_name}-${include.root.locals.environment}"
    eks_cluster_endpoint = "https://000000000000.gr7.${include.root.locals.region}.eks.amazonaws.com"
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
  github_access_token    = get_env("TF_VAR_github_access_token", "github_access_token")
  bitbucket_access_token = get_env("TF_VAR_bitbucket_access_token", "bitbucket_access_token")
  sonarqube_access_token = get_env("TF_VAR_sonarqube_access_token", "sonarqube_access_token")
  slack_access_token     = get_env("TF_VAR_slack_access_token", "slack_access_token")
  argocd_auth_password   = get_env("TF_VAR_argocd_auth_password", "argocd_auth_password")

  jenkins_saml_enabled = false

  values = concat(
    [
      yamlencode({
        controller = {
          jenkinsUrl = format("https://%v", "jenkins.${include.root.locals.environment}.${include.root.locals.domain_name}")

          ingress = {
            enabled          = true
            ingressClassName = "alb"
            annotations = {
              "alb.ingress.kubernetes.io/load-balancer-name" = format("%v-lb-controller", dependency.eks_cluster.outputs.eks_cluster_name)
              "alb.ingress.kubernetes.io/group.name"         = format("%v-lb-controller", dependency.eks_cluster.outputs.eks_cluster_name)
              "alb.ingress.kubernetes.io/target-type"        = "ip"
              "alb.ingress.kubernetes.io/scheme"             = "internet-facing"

              "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
              "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
              "alb.ingress.kubernetes.io/success-codes"        = "200,400"

              "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTPS = 443 }])
              "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
              #"alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP2"
            }
            hostName = format("%v", "jenkins.${include.root.locals.environment}.${include.root.locals.domain_name}")
          }
        }

        persistence = {
          enabled      = false
          storageClass = "gp2"
          size         = "10Gi"
        }
      })
    ]
  )
}
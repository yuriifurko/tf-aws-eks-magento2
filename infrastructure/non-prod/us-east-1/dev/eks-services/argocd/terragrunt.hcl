include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "argocd" {
  path   = "${dirname(find_in_parent_folders())}/_common/argocd.hcl"
  expose = false
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
  argocd_slack_token = get_env("TF_VAR_argocd_slack_token", "argocd_slack_token")

  auth0_domain        = get_env("TF_VAR_auth0_domain", "auth0_domain")
  auth0_client_id     = get_env("TF_VAR_auth0_client_id", "auth0_client_id")
  auth0_client_secret = get_env("TF_VAR_auth0_client_secret", "auth0_client_secret")

  # SSO
  argocd_sso_domain_name = format("https://%v", "argocd.${include.root.locals.environment}.${include.root.locals.domain_name}")

  argocd_server_values = concat(
    [
      yamlencode({
        server = {
          ingress = {
            enabled          = true
            ingressClassName = "alb"

            # https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#aws-application-load-balancers-albs-and-classic-elb-http-mode
            annotations = {
              "alb.ingress.kubernetes.io/load-balancer-name" = format("%v-lb-controller", dependency.eks_cluster.outputs.eks_cluster_name)
              "alb.ingress.kubernetes.io/group.name"         = format("%v-lb-controller", dependency.eks_cluster.outputs.eks_cluster_name)
              "alb.ingress.kubernetes.io/target-type"        = "ip"
              "alb.ingress.kubernetes.io/scheme"             = "internet-facing"

              "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
              "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTPS"
              "alb.ingress.kubernetes.io/success-codes"        = "200,400"

              "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTPS = 443 }])
              "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
              #"alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP2"
            }

            hosts = [
              format("%v", "argocd.${include.root.locals.environment}.${include.root.locals.domain_name}")
            ]
            pathType = "Prefix"
            paths    = ["/"]
            tls      = []
          }
        }
      })
    ]
  )

  argocd_app_values = concat(
    [
      yamlencode({
        projects = [
          {
            name                  = "guestbook"
            namespace             = "argocd"
            description           = "GuestBook Project"
            additionalLabels      = {}
            additionalAnnotations = {}
            finalizers = [
              "resources-finalizer.argocd.argoproj.io"
            ]
            sourceRepos = [
              "*"
            ]
            destinations = [
              {
                namespace = "guestbook"
                server    = "https://kubernetes.default.svc"
              }
            ]
            clusterResourceWhitelist = []
            clusterResourceBlacklist = []
            namespaceResourceBlacklist = [
              {
                kind  = "ResourceQuota"
                group = "*"
              },
              {
                kind  = "LimitRange"
                group = "*"
              },
              {
                kind  = "NetworkPolicy"
                group = "*"
              }
            ]
            namespaceResourceWhitelist = []
            syncWindows = [
              {
                kind     = "allow"
                schedule = "10 1 * * *"
                duration = "1h"
                applications = [
                  "*-dev"
                ]
                manualSync = true
              }
            ]
            sourceNamespaces = [
              "argocd"
            ]
          }
        ]

        applications = [
          {
            name             = "guestbook"
            namespace        = "argocd"
            additionalLabels = {}
            additionalAnnotations = {
              "helm.sh/resource-policy" = "keep"
            }
            finalizers = [
              "resources-finalizer.argocd.argoproj.io"
            ]
            project = "guestbook"
            source = {
              repoURL        = "https://github.com/argoproj/argocd-example-apps.git"
              targetRevision = "HEAD"
              path           = "guestbook"
              directory = {
                recurse = true
              }
            }
            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = "guestbook"
            }
            syncPolicy = {
              automated = {
                prune    = false
                selfHeal = false
              }
            }
            ignoreDifferences = [
              {
                group = "apps"
                kind  = "Deployment"
                jsonPointers = [
                  "/spec/replicas"
                ]
              }
            ]
            info = [
              {
                name  = "url"
                value = "https://argoproj.github.io/"
              }
            ]
          }
        ]

        ## Assign Application to a project
        applicationsets = [
          {
            name      = "guestbook"
            namespace = "argocd"
            generators = [
              {
                git = {
                  repoURL  = "https://github.com/argoproj/argocd-example-apps.git"
                  revision = "HEAD"
                  directories = [
                    {
                      path = "guestbook"
                    }
                  ]
                }
              }
            ]
            strategy = {
              type = "RollingSync"
            }
            template = {
              metadata = {
                name = "{{path.basename}}"
                labels = {
                  project = "{{path.basename}}"
                }
                annotations = {}
              }
              spec = {
                project = "guestbook"
                source = {
                  repoURL        = "https://github.com/argoproj/argocd-example-apps.git"
                  targetRevision = "HEAD"
                  path           = "{{path}}"
                }
                destination = {
                  server    = "https://kubernetes.default.svc"
                  namespace = "guestbook"

                }
                syncPolicy = {
                  automated = {
                    prune    = false
                    selfHeal = false
                  }
                }
                ignoreDifferences = [
                  {
                    group = "apps"
                    kind  = "Deployment"
                    jsonPointers = [
                      "/spec/replicas"
                    ]
                  }
                ]
                info = [
                  {
                    name  = "url"
                    value = "https://argoproj.github.io/"
                  }
                ]
              }
            }
            syncPolicy = {
              preserveResourcesOnDeletion = false
            }
          }
        ]
      })
    ]
  )
}
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "route53_records" {
  path   = "${dirname(find_in_parent_folders())}/_common/route53-records.hcl"
  expose = true
}

dependency "load_balancer_controller" {
  config_path = "${get_terragrunt_dir()}/../eks-services/load-balancer-controller"
  mock_outputs = {
    load_balancer_hostname = "lb"
  }
}

inputs = {
  route53_domain_name = "${include.root.locals.environment}.${include.root.locals.domain_name}"

  route53_domain_records = {
    "argocd" = {
      name   = "argocd"
      type   = "CNAME"
      ttl    = 300
      record = "${dependency.load_balancer_controller.outputs.load_balancer_hostname}"
    },
    "jenkins" = {
      name   = "argocd"
      type   = "CNAME"
      ttl    = 300
      record = "${dependency.load_balancer_controller.outputs.load_balancer_hostname}"
    },
    "grafana" = {
      name   = "argocd"
      type   = "CNAME"
      ttl    = 300
      record = "${dependency.load_balancer_controller.outputs.load_balancer_hostname}"
    }
  }
}
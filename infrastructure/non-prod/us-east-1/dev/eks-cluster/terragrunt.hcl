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

dependency "vpc_network" {
  config_path = "${get_terragrunt_dir()}/../vpc-network"

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

include "eks_cluster" {
  path   = "${dirname(find_in_parent_folders())}/_common/eks-cluster.hcl"
  expose = true
}

inputs = {
  vpc_id             = dependency.vpc_network.outputs.vpc_id
  cluster_subnet_ids = dependency.vpc_network.outputs.vpc_private_subnets_id

  eks_worker_upgrade_ami_enabled = false

  # See all ec2 instance with pricing
  # Ref: https://instances.vantage.sh/
  eks_managed_node_group_enabled = true
  eks_managed_node_groups = {
    "frontend" = {
      enabled    = true
      name       = "eks-managed-frontend"
      subnet_ids = dependency.vpc_network.outputs.vpc_private_subnets_id

      ami_type       = "AL2_x86_64"
      instance_types = ["t3a.small"]
      disk_type      = "gp3"
      disk_size      = 20

      min_size     = 1
      desired_size = 1
      max_size     = 1
    },
    "backend" = {
      enabled    = false
      name       = "eks-managed-backend"
      subnet_ids = dependency.vpc_network.outputs.vpc_private_subnets_id

      instance_types = ["t3a.micro"]
      disk_type      = "gp3"
      disk_size      = 20

      min_size     = 1
      desired_size = 1
      max_size     = 1
    }
  }

  self_managed_node_groups = {
    "default" = {
      enabled = false
      name    = "self-managed-default"

      instance_type = "t3a.micro"
      disk_type     = "gp3"
      disk_size     = 20

      vpc_zone_identifier = [
        dependency.vpc_network.outputs.vpc_private_subnets_id[0]
      ]

      desired_capacity = 1
      min_size         = 1
      max_size         = 1
    }
  }

  eks_access_entry_policy = {
    "devops" = {
      enabled       = true
      principal_arn = "arn:aws:iam::${include.root.locals.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_1b22a202a6b807d7"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      type          = "STANDARD"
      user_name     = "AWSAdministratorAccess"

      kubernetes_groups = null

      association_access_scope_type = "cluster"
    }
  }
}
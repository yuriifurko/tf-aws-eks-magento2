include "root" {
  path   = find_in_parent_folders()
  expose = true
}

include "aws_ecr_repositories" {
  path   = "${dirname(find_in_parent_folders())}/_common/ecr-repositories.hcl"
  expose = false
}

inputs = {
  repositories = {
    "nginx" = {
      image_tag_mutability  = "IMMUTABLE"
      scan_on_push          = true
      expiration_after_days = 7
    },
    "php-fpm" = {
      image_tag_mutability  = "IMMUTABLE"
      scan_on_push          = true
      expiration_after_days = 7
    }
  }

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  # This policy manage by Organization
  manage_registry_scanning_configuration = false

  registry_scan_type = "BASIC"

  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter         = "*"
      filter_type    = "WILDCARD"
    }
  ]
}

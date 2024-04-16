# Set common variables for the environment. This is automatically pulled in the root terragrunt.hcl configuration to
# feed forward to the child modules.

locals {
  project_name = "magento2"
  environment  = "dev"
  domain_name  = "awsworkshop.info"
}
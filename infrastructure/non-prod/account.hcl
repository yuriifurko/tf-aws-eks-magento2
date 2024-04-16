# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.

locals {
  account_id = get_env("TF_VAR_dev_account_id", "dev_account_id")
  profile    = "dev-administrator-access"
}

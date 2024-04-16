#!/bin/bash

echo -e "Generate README"
terraform-docs markdown table --output-file README.md .

echo -e "\n Running validate"
cd infrastructure/non-prod/dev
terragrunt run-all init && terragrunt run-all validate

echo -e "\n Running hclfmt"
terragrunt hclfmt -recursive -check

echo -e "\n Running tfsec"
tfsec

echo -e "\n Running checkov"
checkov -d .
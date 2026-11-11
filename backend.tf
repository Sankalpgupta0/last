# Partial configuration: the shared bucket name lives in backend.hcl (git-ignored).
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {}
}

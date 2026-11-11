provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

locals {
  tags = {
    Project     = var.name
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "terraform"
    Teardown    = "nightly"
  }
}

module "privatebin" {
  source = "./modules/privatebin"

  name                    = var.name
  region                  = var.region
  allowed_cidr            = var.allowed_cidr
  app_port                = var.app_port
  privatebin_version      = var.privatebin_version
  instance_type           = var.instance_type
  noncurrent_version_days = var.noncurrent_version_days
  tags                    = local.tags
}

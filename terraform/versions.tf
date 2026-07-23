terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "neal-street-terraform-state-22072026"
    key          = "rewards/dev/terraform.tfstate"
    region       = "af-south-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

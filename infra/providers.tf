terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

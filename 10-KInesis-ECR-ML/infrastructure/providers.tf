######################################################################
# Terraform Configuration & Providers
######################################################################
terraform {
  cloud {
    organization = "aws-portfolio-omesh"
    workspaces {
      name = "10-kinesis-ecr-ml"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

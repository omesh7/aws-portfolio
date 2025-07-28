terraform {
  cloud {
    organization = "aws-porfolio"
    workspaces {
      name = "01-static-website-s3"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-portfolio-1342"
    key            = "15-cross-cloud-k8s-gitops/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-portfolio-1342-locks"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}




provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = var.tags
  }
}



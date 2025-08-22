terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "01-static-website-s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# US East 1 provider for ACM certificate (required for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = var.tags
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

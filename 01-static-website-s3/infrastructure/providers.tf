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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.7.1"
    }
  }


}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project    = var.project_name
      Owner      = var.project_owner
      Env        = var.environment
      project-no = "01"
    }
  }
}

# US East 1 provider for ACM certificate (required for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Project    = var.project_name
      Owner      = var.project_owner
      Env        = var.environment
      project-no = "01"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token

}

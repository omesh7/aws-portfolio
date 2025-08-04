
terraform {
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "3.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.7.0"
    }
  }


}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "portfolio"
      project-no  = "06"
    }
  }
}


provider "vercel" {
  # Or omit this for the api_token to be read
  # from the VERCEL_API_TOKEN environment variable
  api_token = var.vercel_api_token

  # Optional default team for all resources
  team = var.team
}
    
######################################################################
# Terraform Configuration & Providers
######################################################################
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }

  }


  backend "s3" {
    bucket         = "fastapi-app-test-tf-state"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "fastapi-app-test-tf-lock"
    encrypt        = true
  }

}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "portfolio/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true
  }


  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~>3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "vercel" {
  api_token = var.vercel_api_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}
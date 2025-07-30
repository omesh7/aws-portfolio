variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "ap-south-1"

}

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "01-project-aws-portfolio"

}

variable "github_deploy_user_arn" {
  description = "The ARN of the GitHub deploy user."
  type        = string
  default     = "" # Set this to the actual ARN of your GitHub deploy user
}



variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
  sensitive   = true
}

variable "subdomain" {
  type        = string
  description = "Subdomain to point to S3 (like www or static)"
  default     = "portfolio"
}


variable "project_owner" {
  description = "The owner of the project, used for tagging resources."
  type        = string
  default     = ""

}

variable "environment" {
  description = "The environment for the project (e.g., dev, staging, prod)."
  type        = string
  default     = "portfolio"

}
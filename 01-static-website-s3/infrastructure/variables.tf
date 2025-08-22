variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "01-static-website-aws-portfolio"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment (local or ci)"
  type        = string
  default     = "local"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "subdomain" {
  description = "Subdomain to point to CloudFront"
  type        = string
  default     = "portfolio"
}

variable "enable_custom_domain" {
  description = "Enable custom domain with Cloudflare"
  type        = bool
  default     = false
}

variable "upload_site_files" {
  description = "Whether to upload site files from local dist folder"
  type        = bool
  default     = false
}

variable "site_source_dir" {
  description = "Local directory containing built site files"
  type        = string
  default     = "../site/dist"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "01-static-website-aws-portfolio"
    Environment = "portfolio"
    project-no  = "01"
  }
}
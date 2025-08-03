variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
  sensitive   = true
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}
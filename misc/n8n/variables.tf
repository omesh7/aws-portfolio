variable "aws_region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "prefix" {
  description = "A unique prefix for naming resources to avoid collisions"
  type        = string
  default     = "n8n-portfolio"
}

variable "n8n_hostname" {
  description = "The full custom domain for n8n (e.g., n8n.example.com)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Zone ID of your domain in Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "n8n-automation"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

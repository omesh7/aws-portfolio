variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "" }
variable "vpc_cidr" {
  default = ""
  type    = string
}
variable "public_subnets_cidr" {
  type    = list(string)
  default = ["", ""]
}
variable "app_port" { default = 80 }
variable "min_tasks" { default = 1 }
variable "max_tasks" { default = 2 }

variable "ecr_repository_url" {
  description = "ECR repository URL for the FastAPI application"
  type        = string

}

# # variables.tf
# variable "acm_certificate" {
#   description = "The ACM certificate object to extract DNS validation options"
#   type        = any
# }

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for domain"
}

variable "cloudflare_email" {
  type        = string
  description = "Cloudflare account email"
}

variable "cloudflare_api_key" {
  type        = string
  description = "Cloudflare API key"
}

variable "domain_name" {
  type        = string
  description = "Domain name to be used with the ACM certificate"
}
variable "full_domain_name" {
  type        = string
  description = "Full domain name including subdomain (e.g., app.example.com)"
}

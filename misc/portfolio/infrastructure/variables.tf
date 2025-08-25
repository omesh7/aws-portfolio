variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "portfolio-nextjs-aws-portfolio"
}

variable "vercel_api_token" {
  description = "Vercel API token"
  type        = string
  sensitive   = true
}



variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_site" {
  description = "Cloudflare Site Main Domain (e.g., example.com)"
  type        = string
  default     = "example.com"

}

variable "subdomain" {
  description = "Subdomain for the portfolio site"
  type        = string
  default     = "portfolio"
}

variable "emailjs_service_id" {
  description = "EmailJS Service ID"
  type        = string
  sensitive   = true
}

variable "emailjs_template_id" {
  description = "EmailJS Template ID"
  type        = string
  sensitive   = true
}

variable "emailjs_public_key" {
  description = "EmailJS Public Key"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token for API access"
  type        = string
  sensitive   = true

}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "omesh7"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "aws-portfolio"
}

# modules/cloudflare/variables.tf

variable "acm_certificate" {
  description = "ACM certificate resource with domain_validation_options"
  type        = any
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
}
variable "cloudflare_api_key" {
  description = "Cloudflare API key"
  type        = string
}
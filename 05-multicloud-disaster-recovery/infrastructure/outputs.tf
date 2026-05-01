output "aws_s3_bucket" {
  description = "AWS S3 bucket name"
  value       = module.aws_infrastructure.s3_bucket_name
}

output "aws_cloudfront_domain" {
  description = "AWS CloudFront distribution domain"
  value       = module.aws_infrastructure.cloudfront_domain
}

output "domain_name" {
  description = "Configured domain name"
  value       = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
}

output "weather_app_url" {
  description = "Weather app URL (Primary - AWS)"
  value       = "https://${var.subdomain}.${data.cloudflare_zone.zone.name}"
}

output "weather_app_backup_url" {
  description = "Weather app backup URL (Secondary - GCP)"
  value       = "https://${var.subdomain}-backup.${data.cloudflare_zone.zone.name}"
}

output "gcp_load_balancer_ip" {
  description = "Google Cloud Load Balancer IP"
  value       = module.gcp_infrastructure.load_balancer_ip
}

output "gcp_cdn_url" {
  description = "Google Cloud CDN direct URL"
  value       = module.gcp_infrastructure.cdn_url
}



# Azure outputs - Commented out for AWS-only deployment
# output "azure_storage_account" {
#   description = "Azure storage account name"
#   value       = module.azure_infrastructure.storage_account_name
# }

# output "azure_cdn_endpoint" {
#   description = "Azure CDN endpoint URL"
#   value       = module.azure_infrastructure.cdn_endpoint_url
# }

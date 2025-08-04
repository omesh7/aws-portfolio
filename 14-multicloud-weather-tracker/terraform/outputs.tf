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
  description = "Weather app URL"
  value       = "https://${var.subdomain}.${data.cloudflare_zone.zone.name}"
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

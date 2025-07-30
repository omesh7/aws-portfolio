# Outputs
output "website_url" {
  description = "Website URL"
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
}

output "bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.website_bucket.id
}

output "cloudflare_record_id" {
  description = "Cloudflare DNS Record ID"
  value       = cloudflare_dns_record.site_dns.id
  sensitive   = true
}

data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}

output "portfolio_subdomain" {
  description = "Subdomain for the portfolio"
  value       = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.website_cert.arn
}

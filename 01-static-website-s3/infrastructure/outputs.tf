output "s3_bucket_name" {
  value       = aws_s3_bucket.website_bucket.bucket
  description = "S3 bucket name for static website"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.website_distribution.id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.website_distribution.domain_name
  description = "CloudFront distribution domain name"
}

output "website_url" {
  value       = var.enable_custom_domain ? "https://${var.subdomain}.${data.cloudflare_zone.zone[0].name}" : "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
  description = "Website URL"
}

output "s3_website_endpoint" {
  value       = aws_s3_bucket.website_bucket.bucket_regional_domain_name
  description = "S3 bucket regional domain name"
}
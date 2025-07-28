# Outputs
output "website_url" {
  description = "Website URL"
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
}

output "bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.website_bucket.id
}

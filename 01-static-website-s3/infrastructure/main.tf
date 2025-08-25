# Data source for Cloudflare zone (conditional)
data "cloudflare_zone" "zone" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.cloudflare_zone_id
}

# S3 Bucket for static website
resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.project_name
  force_destroy = true
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Policy for CloudFront and CI/CD access
resource "aws_s3_bucket_policy" "website_policy" {
  bucket     = aws_s3_bucket.website_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.website_pab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ACM Certificate for custom domain
resource "aws_acm_certificate" "website_cert" {
  count             = var.enable_custom_domain ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = "${var.subdomain}.${data.cloudflare_zone.zone[0].name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# ACM Certificate validation DNS records
resource "cloudflare_dns_record" "cert_validation" {
  for_each = var.enable_custom_domain ? {
    for dvo in aws_acm_certificate.website_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "website_cert" {
  count                   = var.enable_custom_domain ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website_cert[0].arn
  validation_record_fqdns = [for record in cloudflare_dns_record.cert_validation : record.name]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  enabled             = true
  default_root_object = "index.html"
  aliases             = var.enable_custom_domain ? ["${var.subdomain}.${data.cloudflare_zone.zone[0].name}"] : []

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.enable_custom_domain ? aws_acm_certificate_validation.website_cert[0].certificate_arn : null
    ssl_support_method       = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version = var.enable_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !var.enable_custom_domain
  }

  tags = var.tags
}

# Cloudflare DNS Record pointing to CloudFront
resource "cloudflare_dns_record" "site_dns" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = aws_cloudfront_distribution.website_distribution.domain_name
  ttl     = 60
  proxied = false

  lifecycle {
    ignore_changes = [content]
  }
}

# Environment-based site file upload
locals {
  use_local_upload = var.environment == "local" && var.upload_site_files
  site_files = local.use_local_upload ? fileset(var.site_source_dir, "**/*") : []
}

# Local file upload (conditional)
resource "aws_s3_object" "site_files" {
  for_each = toset(local.site_files)

  bucket = aws_s3_bucket.website_bucket.id
  key    = each.value
  source = "${var.site_source_dir}/${each.value}"
  etag   = filemd5("${var.site_source_dir}/${each.value}")
  content_type = lookup({
    ".html"  = "text/html",
    ".css"   = "text/css",
    ".js"    = "application/javascript",
    ".json"  = "application/json",
    ".png"   = "image/png",
    ".jpg"   = "image/jpeg",
    ".jpeg"  = "image/jpeg",
    ".gif"   = "image/gif",
    ".svg"   = "image/svg+xml",
    ".ico"   = "image/x-icon",
    ".woff"  = "font/woff",
    ".woff2" = "font/woff2",
    ".ttf"   = "font/ttf",
    ".eot"   = "application/vnd.ms-fontobject"
  }, regex("\\.[^.]+$", each.value), "application/octet-stream")

  depends_on = [aws_s3_bucket_policy.website_policy]
}

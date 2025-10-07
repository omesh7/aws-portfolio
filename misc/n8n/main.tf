# ---------------------------------------------------------------------------------------------------------------------
# AWS CERTIFICATE MANAGER (ACM)
# Request a public SSL/TLS certificate for the custom domain.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate" "n8n_cert" {
  domain_name       = var.n8n_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDFLARE DNS FOR ACM VALIDATION
# Create the DNS record in Cloudflare required by ACM to prove domain ownership.
# ---------------------------------------------------------------------------------------------------------------------

resource "cloudflare_dns_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.n8n_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60
}

# ---------------------------------------------------------------------------------------------------------------------
# ACM CERTIFICATE VALIDATION
# This resource tells Terraform to wait until AWS has successfully validated the certificate.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "n8n_cert_validation" {
  certificate_arn         = aws_acm_certificate.n8n_cert.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.cert_validation : record.name]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY N8N IN A NEW VPC WITH THE CUSTOM DOMAIN CERTIFICATE
# Deploy without certificate first, then update with certificate ARN
# ---------------------------------------------------------------------------------------------------------------------

module "n8n" {
  source  = "elasticscale/n8n/aws"
  version = "4.0.0"

#   prefix          = var.prefix
  url             = "https://${var.n8n_hostname}/"
  fargate_type    = "FARGATE"
#   desired_count   = 1
  certificate_arn = aws_acm_certificate_validation.n8n_cert_validation.certificate_arn
#   tags            = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDFLARE DNS FOR N8N
# Create the final CNAME record to point your custom domain to the n8n load balancer.
# ---------------------------------------------------------------------------------------------------------------------

resource "cloudflare_dns_record" "n8n_dns" {
  zone_id = var.cloudflare_zone_id
  name    = split(".", var.n8n_hostname)[0] # Extracts "n8n" from "n8n.example.com"
  content = module.n8n.lb_dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = false # Disable proxy for ALB health checks
  lifecycle {
    ignore_changes = [content]
  }
}

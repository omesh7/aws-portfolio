

# AWS Resources
module "aws_infrastructure" {
  source               = "./modules/aws"
  domain_name          = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
  aws_region           = var.aws_region
  cloudflare_zone_id   = var.cloudflare_zone_id
  cloudflare_api_token = var.cloudflare_api_token
  lambda_function_url  = aws_lambda_function_url.weather_tracker_url.function_url
}


# Health Check for AWS Primary
resource "aws_route53_health_check" "aws_primary" {
  fqdn              = module.aws_infrastructure.cloudfront_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "AWS Primary Health Check"
  }
}

# Primary DNS Record (AWS)
resource "cloudflare_dns_record" "primary" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = module.aws_infrastructure.cloudfront_domain
  ttl     = 60
  proxied = false

  lifecycle {
    ignore_changes = [content]
  }
}



data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}


# ============================================================================
# GOOGLE CLOUD RESOURCES - Commented out for AWS-only deployment
# Uncomment this entire section when ready to deploy multicloud setup
# ============================================================================

# module "gcp_infrastructure" {
#   source = "./modules/gcp"

#   domain_name         = "${var.subdomain}-backup.${data.cloudflare_zone.zone.name}"
#   gcp_region          = var.gcp_region
#   gcp_project_id      = var.gcp_project_id
#   lambda_function_url = aws_lambda_function_url.weather_tracker_url.function_url
# }

# resource "cloudflare_dns_record" "secondary" {
#   zone_id = var.cloudflare_zone_id
#   name    = "${var.subdomain}-backup"
#   type    = "A"
#   content = module.gcp_infrastructure.load_balancer_ip
#   ttl     = 60
#   proxied = false
# }

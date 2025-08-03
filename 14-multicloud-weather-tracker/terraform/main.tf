

# AWS Resources
module "aws_infrastructure" {
  source = "./modules/aws"

  domain_name          = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
  aws_region           = var.aws_region
  cloudflare_zone_id   = var.cloudflare_zone_id
  cloudflare_api_token = var.cloudflare_api_token
}

# Azure Resources
module "azure_infrastructure" {
  source = "./modules/azure"

  domain_name    = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
  azure_location = var.azure_location
  resource_group = var.azure_resource_group
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
}

# Secondary DNS Record (Azure) - for manual failover
resource "cloudflare_dns_record" "secondary" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.subdomain}-backup"
  type    = "CNAME"
  content = module.azure_infrastructure.cdn_endpoint_fqdn
  ttl     = 60
  proxied = false
}

data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}


resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group
  location = var.azure_location

  tags = {
    environment = "production"
    project     = "weather-tracker"
  }
}
